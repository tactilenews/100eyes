# AI Agent Instructions

## Docmap - Seek Documentation

**Before any investigation or code exploration**, run `npm run docmap`, then read the relevant documentation. Mandatory for every task.

### Essential Documentation

Always read before any investigation or work:

- `docs/architecture.md` — core domain models, multi-tenancy, request lifecycle, adapter layer overview
- `docs/code-style.md` — Rails conventions, ViewComponent pattern, service objects, Rubocop rules


## Agent Operations

This section documents how an AI agent (e.g. the factory agent on the agent server) should
work with this repository. All commands assume the repo is available at the path documented
under **Project**.

### Project

- VCS: github
- GitHub repo: `tactilenews/100eyes`
- PR base branch: `datenfreunde-staging`
- Branch prefix: `factory`
- Agent server path: `/home/ubuntu/100eyes`

### GitHub

- GitHub CLI (gh) is authenticated and configured

### Testing

#### Setup (run once per session)

Build the app image:
```bash
cd /home/ubuntu/100eyes && docker compose build app 2>&1 | tail -5
```

Ensure `.env.test` exists with minimum required env vars:
```bash
[ -f /home/ubuntu/100eyes/.env.test ] || echo "ATTR_ENCRYPTED_KEY=test_key_00000000000000000000000" > /home/ubuntu/100eyes/.env.test
```

Start the test database and Chrome (required for system specs):
```bash
docker compose -f /home/ubuntu/100eyes/docker-compose.yml \
  -f /home/ubuntu/100eyes/docker-compose.override.yml \
  up -d db chrome
```

Set up the test database and build assets:
```bash
docker compose run --rm \
  --env-file /home/ubuntu/100eyes/.env.test \
  -e RAILS_ENV=test \
  app bundle exec rails db:create db:schema:load 2>&1

# Build JS/CSS once (assets service runs watch mode by default — override with explicit command)
docker compose run --rm assets npm run build:js && npm run build:css 2>&1

docker compose run --rm \
  --env-file /home/ubuntu/100eyes/.env.test \
  -e RAILS_ENV=test \
  app bundle exec rails assets:precompile 2>&1
```

#### Linting

```bash
docker compose run --rm app bundle exec rubocop --no-color 2>&1
```

#### Full test suite

```bash
docker compose run --rm \
  --env-file /home/ubuntu/100eyes/.env.test \
  -e RAILS_ENV=test \
  app bundle exec rspec 2>&1
```

Run a subset (e.g. after identifying specific failures):
```bash
docker compose run --rm \
  --env-file /home/ubuntu/100eyes/.env.test \
  -e RAILS_ENV=test \
  app bundle exec rspec <file_or_pattern> 2>&1
```

#### Notes

- Do **not** skip system specs — CI runs them, so skipping locally gives false confidence.
- The `assets` service runs `npm run dev` (watch mode) by default. Always override it with
  `docker compose run --rm assets npm run build:js && npm run build:css` for a one-time build in CI/agent contexts.
- `ATTR_ENCRYPTED_KEY` must be set or `attr_encrypted` will raise on model load.

### Preview

- **Compose file**: `docker-compose.preview.yml`
- **Health path**: `/health`
- **Env template**: `.env.preview` (substitutes `$PREVIEW_HOST` and `$DB_NAME`)

Preview environments are deployed by the `factory-preview` skill to `previews.labs.datenfreunde.net`.
URL pattern: `pr-{number}-100eyes.previews.labs.datenfreunde.net`

Signal and email are stubbed out in `.env.preview` — the preview is UI/DB only.
The app image is built from source on the preview server; first deploy may take several minutes.
