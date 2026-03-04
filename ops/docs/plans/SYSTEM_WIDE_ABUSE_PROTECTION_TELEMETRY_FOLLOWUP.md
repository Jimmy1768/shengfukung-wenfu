# System-Wide Abuse Protection Telemetry Follow-Up

## Goal
- Keep threshold tuning lightweight and evidence-based after A-E rollout completion.

## Weekly Task (10-15 min)
1. Run:
   - `cd rails && bin/rails api_protection:report WINDOW_MINUTES=10080 LIMIT=50`
2. Review:
   - top throttled paths
   - repeated blocked scopes
   - false-positive signs from support feedback
3. Decide:
   - keep thresholds
   - or update `rails/app/lib/api_protection/policy.rb` for one class only

## Monthly Task
1. Run dry-run cleanup check:
   - `cd rails && bin/rails api_protection:cleanup DRY_RUN=true`
2. Confirm retention windows still match ops needs:
   - low-signal: 48h
   - high-signal: 60d

## Change Logging
- When thresholds change, append a one-line note in commit message:
  - `api_protection: tune <endpoint_class> <old_limit>/<old_window> -> <new_limit>/<new_window>`
