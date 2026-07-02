---
title: Testing Guide
summary: How to run tests, write new specs, and avoid common pitfalls in this codebase.
read_when:
  - writing a new spec or unsure which type to write
  - debugging a failing test
  - setting up the test environment for the first time
---

# Testing Guide

## Stack

- **RSpec** with Rails integration (`rspec-rails`)
- **FactoryBot** for test data
- **Faker** (locale: `:de`) for random data
- **Capybara + Cuprite** for system specs (real Chrome via `docker-compose` `chrome` service)
- **VCR** for recording/replaying HTTP interactions with external APIs (`spec/vcr_setup.rb`, cassettes in `vcr_cassettes/`)

## Running Tests (Docker)

All tests run inside Docker. See `AGENTS.md` for the full setup sequence (build image, start db + chrome, etc.).

```bash
# Full suite
docker compose run --rm --env-file .env.test -e RAILS_ENV=test app bundle exec rspec

# Subset
docker compose run --rm --env-file .env.test -e RAILS_ENV=test app bundle exec rspec spec/models/contributor_spec.rb

# System specs only
docker compose run --rm --env-file .env.test -e RAILS_ENV=test app bundle exec rspec spec/system/
```

**Do not skip system specs** — CI runs them and they catch regressions not covered by unit tests.

## Spec Types and Where They Live

| Type | Path | When to write |
|------|------|---------------|
| Model | `spec/models/` | Validations, scopes, instance methods |
| Request | `spec/requests/` | Controller/routing behaviour, HTTP status codes |
| Component | `spec/components/` | ViewComponent rendering |
| System | `spec/system/` | End-to-end browser flows |
| Job | `spec/jobs/` | Background job behaviour |
| Adapter | `spec/adapters/` | Inbound/outbound adapter logic |
| Mailbox | `spec/mailboxes/` | Inbound email parsing |
| Service | `spec/services/` | Service object logic |

## Factories

Factories live in `spec/factories/`. Key ones:

- `create(:organization)` — creates an org with a `BusinessPlan` (defaults to "Editorial Basic"). Includes all required fields (phone numbers, email, etc.).
- `create(:contributor)` — email contributor by default. Use traits for other channels:
  - `:telegram_contributor` — sets `telegram_id`, clears `email`
  - `:signal_contributor` — sets `signal_phone_number`, clears `email`
  - `:whats_app_contributor` — sets `whats_app_phone_number`, clears `email`
  - `:threema_contributor` — sets `threema_id`, clears `email`
- `create(:user)` — requires association with an organization: `create(:user, organizations: [org])`
- `create(:request, user: user, organization: org)` — always needs both

## Pitfalls

**`ATTR_ENCRYPTED_KEY` must be set** or any model load will raise. The `.env.test` file must contain it. AGENTS.md has the bootstrap command.

**`User` before_create sets `must_reset_password: true`** — if a test signs in as a user and gets redirected to password reset, the factory needs `must_reset_password: false`.

**`Organization` after_create_commit callbacks** fire on `create(:organization)` — `set_telegram_webhook` will attempt an HTTP call. Stub external calls or use VCR.

**System specs need Chrome running** — `docker compose up -d chrome` must be running. Cuprite connects to it via CDP.

**VCR cassettes** — adapter specs that hit external APIs should use VCR. Cassettes are stored in `vcr_cassettes/`. If a cassette is missing, the test will fail with a real HTTP attempt error.

## Linting

```bash
docker compose run --rm app bundle exec rubocop --no-color
```

Line length max is 140. `app/components/**/*.rb` is excluded from the line length rule.
