# Cache Payload Subsystem

This subsystem lets every client (web, Expo, automation) request pre-built payloads instead of assembling large responses on the single JS thread. The database tables (`client_checkins`, `client_cache_states`, `client_cache_metrics`, `cache_repair_tasks`) exist in all projects; this README explains how to wire them up consistently.

## Concepts

- **State key** – string identifier for a payload (example: `admin.dashboard`). Each key maps to a builder class.
- **Client check-in** – represents a signed-in device/browser. All cache state rows hang off `ClientCheckin`.
- **Cache state** – `client_cache_states` row per user/client/state key tracking `needs_refresh`, `version`, and optional `context_reference`.
- **Cache metrics** – aggregated counters (hits/misses/refreshes) per user/client + key for observability.
- **Repair tasks** – queued when a payload fails to build so workers can retry without blocking clients.

## File Layout

```
app/
  lib/cache/storage.rb                # TTL wrapper around Rails.cache/Redis
  services/cache_payloads/
    base_builder.rb                   # common helpers for payload builders
    registry.rb                       # maps state_key -> builder class
    fetch_service.rb                  # orchestrates read/build/write/metrics
    refresher.rb                      # marks state refreshed + bumps version
    invalidator.rb                    # flips needs_refresh when data changes
jobs/cache_payload_refresh_job.rb     # optional cron hook
workers/cache/cache_refresh_worker.rb # background rebuild for specific keys
```

Copy these files into any project using this schema. Add builder classes per payload under `app/services/cache_payloads/`.

## Builder Pattern

1. Create `CachePayloads::<Feature>Builder < CachePayloads::BaseBuilder`.
2. Implement `state_key` (string) and `build_payload` (returns a Hash/Array ready for JSON).
3. Register the builder in `CachePayloads::Registry.register("state.key", CachePayloads::FeatureBuilder)`. Do this in an initializer or the builder file.
4. Keep builders read-only. Any DB writes stay inside services/controllers elsewhere.

## Fetch Flow

1. Client asks `/api/cache_payloads/:state_key`.
2. Controller resolves the `ClientCheckin` (from device headers/cookies).
3. `CachePayloads::FetchService.call(state_key:, user:, client_checkin:, force_refresh: false)`:
   - Checks `ClientCacheState` for `needs_refresh` or missing `context_reference`.
   - Calls the registered builder if needed and writes payload to `Cache::Storage` (default TTL 5 minutes).
   - Updates metrics (`hits_count`, `misses_count`, `refresh_count`).
   - Returns `{ version:, payload:, generated_at: }`.
4. Front-end keeps the payload until `needs_refresh` flips back to true.

## Invalidation Flow

- When a write occurs (admin updates profile, payment posted, etc.), call `CachePayloads::Invalidator.call(state_keys:, scope:)`.
- Invalidator finds relevant `client_cache_states` rows (by slug/user/client) and sets `needs_refresh = true`.
- Optionally enqueue `Cache::CacheRefreshWorker` to rebuild in the background so the next read is fast.

## Metrics & Repairs

- `ClientCacheMetric` stores hit/miss/refresh counts. Update them inside `FetchService` and use them for dashboards.
- If a builder raises, catch the exception, persist an entry in `cache_repair_tasks` (status `pending`), and let `CachePayloadRefreshJob` + worker retry later. Clients can fall back to a stale payload or display a friendly error.

## Storage

- `Cache::Storage` wraps your cache backend. Default TTL is 5 minutes (`CACHE_PAYLOAD_TTL` env override).
- Namespacing: include slug + state key + user id in the cache key so multiple temples can coexist without collisions.
- Provide `read`, `write`, and `delete` helpers. Builders should not talk to Rails.cache directly.

## Implementation Steps (per project)

1. Copy this README + subsystem files into the repo (`ops/docs/CACHE_README.md`, `app/lib/cache/storage.rb`, etc.).
2. Ensure migrations for `client_checkins`, `client_cache_states`, `client_cache_metrics`, `cache_repair_tasks` exist.
3. Implement builder classes for the payloads you care about. Start with admin dashboard/account dashboard.
4. Add controller endpoints (or GraphQL resolvers) that call `CachePayloads::FetchService`.
5. Update services/controllers that modify related data to call `CachePayloads::Invalidator`.
6. Enable the Sidekiq worker + job if you need proactive rebuilds or repair flows.
7. Monitor metrics to tune TTLs and detect cache drift.

## Notes

- Expo/mobile clients should reuse these payloads 1:1, omitting only payloads you intentionally exclude from small screens.
- Keep builders deterministic and side-effect free. All personalization (per temple, per locale) happens via arguments/options.
- If a project requires longer TTLs, override `Cache::Storage.default_ttl` but keep per-key overrides cheap to update.
