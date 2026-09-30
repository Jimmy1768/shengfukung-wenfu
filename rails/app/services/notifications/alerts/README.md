# Notifications Alerts

Top-level alerting helpers live under `services/notifications/alerts/`. These files take structured events from dispatching, Sidekiq failures, or notification transport problems and:

- log them as JSON lines via `Notifications::Logging::EventLogger` under `log/notifications/YYYY-MM-DD.log`
- send throttled Brevo emails to the ops/dev recipient directly via `Notifications::Alerts::AlertSender`

## Hooking up new alerts

1. **Log an event and send an alert**  
   Call `Notifications::Alerts::AlertSender.call` with `alert_key`, `subject`, and `body`. The `alert_key` determines the throttling bucket (5-minute window) so duplicate emails are avoided.  

2. **Use DeliveryFailure helpers**  
   If the failure is tied to a channel, prefer `Notifications::Alerts::DeliveryFailure.call(channel:, user:, details:, resource_key:)`. It writes the `notifications.alert.delivery_failure` event for you and then sends the appropriate email.  

3. **Sidekiq hook**  
   Sidekiq errors are already wired through `Notifications::Alerts::SidekiqFailureHandler` via `config/initializers/sidekiq_notification_alerts.rb`. Add new event keys inside that handler if you want other job/drop-in alert flows.

   Two things about that handler are easy to get wrong, both fixed 2026-08-28:

   - **Sidekiq passes job details nested, or not at all.** A real job failure
     arrives as `{context: "...", job: job_hash}` — class/args/jid/queue live
     one level down at `context[:job]`, string-keyed because the payload is
     JSON-derived, while the wrapping hash is symbol-keyed. An internal
     failure with no job in flight (a Redis-unreachable fetch loop, say)
     passes **no context at all**, defaulting to `{}` — which is truthy, so a
     `return unless context` guard does not catch it. Reading `context[:class]`
     at the top level, as the handler originally did, silently yielded
     `"unknown"` for *every* failure, not just Redis ones.
   - **Throttle keys must not collapse.** Job failures key on
     `job_class + exception_class`; keying on job class alone means a new
     failure mode hides behind an already-alerted one. Infra failures (no job)
     key on exception class, so an unrelated infra failure is not hidden behind
     another. This used to claim that a Redis blip and a sustained outage
     "throttle together". They never did: the throttle's keys are in Redis, so
     during a Redis outage it could not throttle at all. See below.

   **A Redis connection error does not email until Redis has been unreachable
   for 60 seconds** — settled 2026-09-30. With no job in flight, any
   `RedisClient::ConnectionError` (that includes `CannotConnectError` and
   `ReadTimeoutError`) is logged as always and then counted by
   `Notifications::Alerts::RedisOutageTracker` instead of mailed:

   - Nothing is sent until connection errors have persisted for 60 seconds.
   - Then exactly **one** email for that outage, saying how long Redis has been
     unreachable and that Sidekiq resumes on its own when it returns. Further
     errors in the same outage send nothing more.
   - An outage ends when 30 seconds pass with no connection error. The next one
     starts a new outage, which has to last 60 seconds to alert.

   Why: every Sidekiq processor thread blocks in `BRPOP` on Redis and retries a
   failed fetch after a one-second sleep, so any gap in Redis reaches the error
   handler at once and then about once a second per thread. On 2026-09-30 a
   two-second Redis restart — `needrestart` after an unattended OpenSSL upgrade —
   emailed from production and staging, and a nine-second read timeout emailed
   again. Neither needed anyone.

   **Why the tracker is in memory and not the throttle.** `AlertThrottler` keeps
   its keys in `Rails.cache`, which is Redis, and fails *open*: when it cannot
   reach its store it allows the alert. So during a Redis outage — exactly when
   this matters — the throttle does not throttle, and a key written before the
   outage cannot be read to suppress anything either. The tracker's state is
   per process, in memory, behind a `Mutex`, on a monotonic clock, and touches
   neither `Rails.cache` nor Redis. Each process decides for itself, so
   production and staging each send their own one email, which is correct:
   they are separate deployments. The one email still goes through
   `AlertSender`, whose Brevo call is synchronous HTTP and does not need Redis,
   with a throttle key unique to the outage, so that once Redis is back an
   earlier outage's key cannot swallow a later outage's only email.

   Unchanged: a job failure (a job in flight) and any infra error that is not a
   Redis connection error alert immediately through the throttle, as before.

   The handler is registered in Sidekiq's **3-argument** form. `Sidekiq::Config#handle_exception`
   inspects the arity of the registered proc itself, so a 2-arg proc logs a
   deprecation on every single invocation even if what it calls accepts three.

4. **Extending throttling**  
   `AlertThrottler` stores keys in `Rails.cache` with a 5-minute TTL. Provide a custom `throttle_key` to `AlertSender` when the default (derived from `alert_key`) is too generic.  
   `Rails.cache` is Redis, and the throttler fails open when it cannot reach it. Do not rely on it to limit any alert that fires *because* Redis is unreachable — it cannot, and will allow every one.

## Inspecting logged alerts

- Use `tail -f log/notifications/*.log` to watch alerts in development or on the server. Each line is JSON with `event`, `level`, `details`, and `timestamp`.  
- Files roll daily (`YYYY-MM-DD.log`) and the pruner removes entries older than `NOTIFICATIONS_LOG_KEEP_DAYS` (default 60 days).  
- The same log files contain the structured entries from `DispatchEvent`, `Push::Delivery`, `Email::Delivery`, and all alert helpers, so you can correlate alert emails with the log trail.

Keep each alert message concise but descriptive, and rely on the log files for richer context (stack traces, payloads, etc.). If you ever need to ship the logs elsewhere, point your log shipper at `log/notifications/*.log`.
