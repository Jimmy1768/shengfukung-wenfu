# Notification Tests

Every file under `services/notifications/test/` is designed to deliberately exercise an alert path so you can verify your monitoring, throttling, and email flows work before something real goes wrong.

## Available tests

- `SidekiqTransientFailure`: raises twice, then succeeds on the third attempt. Useful to ensure your retry behavior still fires alerts but recovers gracefully.  
- `SidekiqFatalFailure`: raises a fatal error immediately so a Sidekiq job exhausts retries and lands in your alert handler.  
- `PushFailure`: triggers `Notifications::Alerts::DeliveryFailure` for the push channel (no real push call).  
- `EmailFailure`: triggers `Notifications::Alerts::DeliveryFailure` for the email channel.

## Running the tests

1. Enqueue the smoke test worker, which orchestrates all of the above:

```bash
bundle exec sidekiq
# in another terminal
bundle exec rails runner 'Notifications::AlertSmokeTestWorker.perform_async'
```

2. The worker will:
   - Run the transient failure service (raises before succeeding)  
   - Enqueue `AlertSmokeTestFatalWorker`, which triggers the fatal failure and alerts via the Sidekiq failure handler  
   - Invoke `PushFailure` and `EmailFailure`, which log structured events and send throttled alert emails

3. Observe the resulting JSON events in `log/notifications/*.log` and confirm the emails arrive (one per 5 minutes thanks to `AlertThrottler`).

4. Use `tail -f log/notifications/*.log` to watch the alert stream in real time; search for keys like `notifications.alert.delivery_failure`, `notifications.sidekiq.failure`, and `notifications.push.result`.

5. If you want to isolate a single path, call the service directly in `rails runner` (e.g., `Notifications::Test::PushFailure.call`) and then inspect the log file for that timestamp.

Keep these tests handy for deployments or whenever you tweak notification or alerting code; they guarantee every path from push/email failure to Sidekiq errors is covered. If you add new services under this folder, document them here along with how to trigger and validate them.
