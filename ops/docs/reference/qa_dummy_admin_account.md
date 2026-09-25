# QA Dummy Admin Account

## Purpose

A persistent, well-known account that exists specifically to simulate what
a real, limited-permission temple admin sees — on production, without
needing a real staff member's account for it.

This is distinct from the Director's own account, which is owner of every
temple by default for full operational access — that account is not really
for debugging, and (correctly) always sees everything, including owner-only
surfaces like Billing. The QA dummy admin is never granted the `owner`
membership role anywhere, so it also correctly proves owner-only gates stay
blocked, not just that capability-gated features hide/show correctly.

Local development/QA against the disposable dev or test database is
unrelated to this — create throwaway users there freely, same as any other
test fixture. This account exists only because production data can't be
freely fabricated the same way.

## Account

- Email: `qa-dummy-admin@sourcegridlabs.com` (`AppConstants::Emails.qa_dummy_admin_email`)
- One shared identity across every temple it's ever assigned to — not
  recreated per temple.

## Login is gated by the env var, not the stored password hash

`Admin::SessionsController#can_sign_in?` checks this one account's password
against the current `QA_DUMMY_ADMIN_PASSWORD` environment value directly,
not its `encrypted_password` column. Every other account is unaffected --
this is a narrow, email-scoped special case, not a change to how
authentication works generally.

Practical effect: the password lives only in `/etc/default/shengfukung-demo-env`
in production (never in git), and removing that line makes the account
unusable immediately, even though its database row and hash still exist.
Rotating the password means updating that one env line -- the account
picks it up on the next login attempt, no re-running the seed task
required (though re-running it also keeps the stored hash in sync, as a
fallback that isn't actually load-bearing for login itself).

## Usage

Assign it to a temple with a fresh, all-false permission baseline:

```bash
# First time only, sets the login password:
bin/rails "admin_controls:seed_qa_dummy_admin[<temple-slug>]" PASSWORD=<password>
# or: QA_DUMMY_ADMIN_PASSWORD=<password> bin/rails "admin_controls:seed_qa_dummy_admin[<temple-slug>]"

# Every subsequent run (any temple, no password needed):
bin/rails "admin_controls:seed_qa_dummy_admin[<temple-slug>]"
```

This creates the account if it doesn't exist yet, attaches an `admin`-role
membership (never `owner`) to the given temple, and resets its
`AdminPermission` row to all-false — a clean baseline every time, not an
accumulation of whatever was granted during a previous debug session.

Toggle specific capabilities for the actual test through the real
Permissions admin page (signed in as a real owner), not through a second
script — that exercises the same UI a real temple owner would use to grant
a real admin a permission, which is the actual thing worth proving.

Remove it from a temple when done (leaves the account itself intact for
reassignment elsewhere):

```bash
bin/rails "admin_controls:remove_qa_dummy_admin[<temple-slug>]"
```

## Multi-temple

The account can hold memberships on more than one temple at once — assigning
it to a new temple doesn't remove it from a previous one. Remove it
explicitly from a temple when that debugging session is done, if you don't
want it lingering there.

## Source

`rails/lib/tasks/admin_controls.rake` — `seed_qa_dummy_admin`,
`remove_qa_dummy_admin`.
