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

4. **Extending throttling**  
   `AlertThrottler` stores keys in `Rails.cache` with a 5-minute TTL. Provide a custom `throttle_key` to `AlertSender` when the default (derived from `alert_key`) is too generic.

## Inspecting logged alerts

- Use `tail -f log/notifications/*.log` to watch alerts in development or on the server. Each line is JSON with `event`, `level`, `details`, and `timestamp`.  
- Files roll daily (`YYYY-MM-DD.log`) and the pruner removes entries older than `NOTIFICATIONS_LOG_KEEP_DAYS` (default 60 days).  
- The same log files contain the structured entries from `DispatchEvent`, `Push::Delivery`, `Email::Delivery`, and all alert helpers, so you can correlate alert emails with the log trail.

Keep each alert message concise but descriptive, and rely on the log files for richer context (stack traces, payloads, etc.). If you ever need to ship the logs elsewhere, point your log shipper at `log/notifications/*.log`.
