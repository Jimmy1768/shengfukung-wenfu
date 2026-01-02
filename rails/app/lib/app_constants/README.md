# Rails App Constants

This directory houses Rails-only configuration modules. They can reference
`AppConstants::Project` (which reads `shared/app_constants/project.json`) but
should only include backend-specific concerns:

- `project.rb` – shared slug/name roots + helpers for service filenames.
- `env.rb` – helpers for resolving `.env` filenames per environment.
- `locales.rb` – available locale metadata for the backend.
- `origins.rb` – URLs for marketing/admin surfaces.
- `email_addresses.rb` – default notification senders.
- `sessions.rb` – centralizes session key naming per admin namespace.

Add new modules here when the configuration is Rails-specific. If multiple
surfaces need the same value, add it to `project.json` instead so every app
can read the same source of truth.
