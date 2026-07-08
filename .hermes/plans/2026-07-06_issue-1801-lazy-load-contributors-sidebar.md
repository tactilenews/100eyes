# Issue #1801 — Lazy Load Contributors Sidebar: Session State

> **Status: IMPLEMENTATION COMPLETE — PR open, preview env deployed, awaiting Traefik cert fix**

---

## Goal

Lazy-load the contributors list sidebar on the contributor show page (`organizations/contributors#show`) so the current contributor's profile is immediately visible without waiting for all active contributors to load.

---

## Current State (as of 2026-07-06 session end)

### Branch
```
factory/1801-lazy-load-contributors-list-on-contributors-show
```
Based on `datenfreunde-staging`, rebased and pushed to origin.

### PR
**https://github.com/tactilenews/100eyes/pull/2169** — open, base: `datenfreunde-staging`

### Preview environment
- **Container:** running on `previews.labs.datenfreunde.net` at `/home/ubuntu/previews/100eyes/pr-2169`
- **URL (pending cert):** `https://pr-2169-100eyes.previews.labs.datenfreunde.net`
- **HTTP works:** `http://pr-2169-100eyes.previews.labs.datenfreunde.net` returns 301→HTTPS (app is up)
- **Blocker:** Traefik cannot obtain ACME cert — DNS-01/Route53 challenge fails because the preview server has no EC2 IMDS role and no AWS credentials in the Traefik container env.
  - Error: `route53: failed to determine hosted zone ID: operation error Route 53: ListHostedZonesByName, get identity: get credentials: failed to refresh cached credentials, no EC2 IMDS role found`
  - Matt is debugging this as of session end.

### Tests
- `spec/requests/contributors_spec.rb` ran with 34 examples, 0 failures (targeted spec).
- Full suite was running when session context was interrupted — result unknown.

---

## What Was Implemented

### Approach
Turbo Frame with `src:` eager fetch — page renders immediately, frame fires right after load to populate the full sidebar. The current contributor's row is rendered eagerly inside the frame placeholder so navigation is usable instantly.

### Files changed

#### `config/routes.rb`
Added `sidebar` to the contributors collection routes:
```ruby
collection do
  get 'count'
  get 'sidebar'   # ← added
end
```
Route helper: `sidebar_organization_contributors_path(@organization, active_id: @contributor.id)`

#### `app/controllers/organizations/contributors_controller.rb`
- Removed `before_action :contributors_sidebar, only: %i[show update]`
- Removed private `contributors_sidebar` method
- Added `sidebar` action:
```ruby
def sidebar
  @contributors_sidebar = @organization
                          .contributors
                          .active
                          .with_attached_avatar
  @active_contributor_id = params[:active_id].to_i
  render layout: false
end
```

#### `app/views/organizations/contributors/show.html.erb`
Replaced the eager sidebar loop with a Turbo Frame pointing to the new endpoint. The current contributor's row renders eagerly inside the frame as a placeholder:
```erb
<%= tag.turbo_frame id: 'contributors-sidebar',
      src: sidebar_organization_contributors_path(@organization, active_id: @contributor.id) do %>
  <%# Eager placeholder — just the current contributor, rest loads async %>
  <%= c 'sidebar_item', active: true do %>
    <%= c 'contributor_row', organization: @organization, contributor: @contributor, style: :compact %>
  <% end %>
<% end %>
```

#### `app/views/organizations/contributors/sidebar.html.erb` (new file)
```erb
<%= tag.turbo_frame id: 'contributors-sidebar' do %>
  <% @contributors_sidebar.each do |contributor| %>
    <%= c 'sidebar_item', active: contributor.id == @active_contributor_id do %>
      <%= c 'contributor_row', organization: @organization, contributor: contributor, style: :compact %>
    <% end %>
  <% end %>
<% end %>
```

#### `spec/requests/contributors_spec.rb`
- Updated the existing "doesn't have the other contributor in the sidebar" context — that test now correctly targets the `sidebar` endpoint (the show page no longer renders sidebar contributors directly).
- Added `describe 'GET /sidebar'` block with:
  - success (200) spec
  - renders the contributor's name
  - does not render contributors from other organizations

---

## Remaining Work

### 1. Traefik cert (infra — Matt's side)
Fix ACME DNS-01 challenge on the preview server. Options:
- Grant the preview EC2 instance an IAM role with Route53 write access, OR
- Switch Traefik to HTTP-01 challenge (simpler, no AWS dependency — works as long as port 80 is publicly reachable)

### 2. Verify in preview
Once cert is resolved, open `https://pr-2169-100eyes.previews.labs.datenfreunde.net`, navigate to a contributor show page, and confirm:
- Profile panel visible immediately on page load
- Sidebar populates ~instantly after (network waterfall: sidebar request fires after DOMContentLoaded)
- Active contributor row highlighted correctly

### 3. Full test suite result
The full `rspec` run was interrupted mid-session. Once the preview is verified, run:
```bash
cd /home/ubuntu/100eyes && docker compose run --rm \
  --env-file /home/ubuntu/100eyes/.env.test \
  -e RAILS_ENV=test \
  app bundle exec rspec 2>&1 | tail -20
```
Expected: no regressions. The only spec that needed updating was `contributors_spec.rb` (already done).

### 4. Register preview in registry (optional)
If the `preview-ctl` binary is available and the cert is resolved:
```bash
ssh ubuntu@previews.labs.datenfreunde.net \
  /home/ubuntu/bin/preview-ctl register \
  pr-2169-100eyes 100eyes 2169 \
  factory/1801-lazy-load-contributors-list-on-contributors-show \
  https://pr-2169-100eyes.previews.labs.datenfreunde.net
```

### 5. Post preview URL as PR comment (after cert)
```bash
gh pr comment 2169 --repo tactilenews/100eyes \
  --body "Preview deployed: https://pr-2169-100eyes.previews.labs.datenfreunde.net"
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| Turbo Frame `src:` (not `loading: :lazy`) | Sidebar is always visible; `src:` fires immediately after page load. `loading: :lazy` only fires when the frame scrolls into view — wrong UX here. |
| Collection route `/sidebar` (not member) | The sidebar shows all contributors, not one. Matches `messages-by-contributor` pattern in `requests_controller`. |
| `active_id` query param | The sidebar action has no `@contributor` (it's a collection action). Pass the current contributor's ID as a param so the sidebar can highlight the active row. |
| Eager placeholder in frame | Render the current contributor's row immediately inside the turbo-frame so the user sees something useful before the async load completes. |
| `render layout: false` in `sidebar` action | Returns only the turbo-frame HTML fragment — no full page layout. Same pattern as `InlineMetrics`. |

---

## Preview Server State

```
Container: pr-2169-app-1   (running)
Container: pr-2169-db-1    (running, healthy)
Dir:       /home/ubuntu/previews/100eyes/pr-2169
Env file:  .env.resolved (generated from .env.preview)
Compose:   docker-compose.preview.yml
```

To tear down if needed:
```bash
ssh ubuntu@previews.labs.datenfreunde.net bash -s << 'ENDSSH'
cd /home/ubuntu/previews/100eyes/pr-2169
export PREVIEW_ID=pr-2169-100eyes
export PREVIEW_HOST=pr-2169-100eyes.previews.labs.datenfreunde.net
export DB_NAME=100eyes_pr_2169
docker compose -f docker-compose.preview.yml down -v
ENDSSH
```
