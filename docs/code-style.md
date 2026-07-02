---
title: Code Style & Conventions
summary: Rails conventions, patterns, and project-specific rules to follow when writing code.
read_when:
  - unsure how to structure a new class or feature
  - reviewing code for style consistency
  - adding a new UI component or service
---

# Code Style & Conventions

## General

- Ruby: Rubocop enforced (`rubocop-rails`). Config in `.rubocop.yml` (inherits `.rubocop_todo.yml`).
- Line length max: **140**. Exception: `app/components/**/*.rb` is excluded.
- All files start with `# frozen_string_literal: true`.

## Models

- Keep business logic in models only when it's clearly domain behaviour. Anything more complex belongs in a service object.
- Use `scope` for named queries. Scopes are chainable; prefer them over class methods for queries.
- Encrypted fields via `attr_encrypted` — credentials live on `Organization`. Key comes from `ATTR_ENCRYPTED_KEY` env var (Base64-decoded).
- Multi-channel phone numbers: normalized via `phony_normalize` (default country: `DE`).
- Tagging via `acts_as_taggable_on` with `acts_as_taggable_tenant :organization_id` for org-scoped tags.
- Full-text search via `pg_search` with `multisearchable`. Always include `organization_id` in `additional_attributes` to scope results.

## Controllers

- All organization-scoped resources are routed under `/:organization_id` — controllers receive `params[:organization_id]`.
- Use concerns (`app/controllers/concerns/`) for shared controller behaviour.
- Webhook controllers live under their channel namespace (e.g. `whats_app/`, `telegram/`).
- Onboarding controllers live under `app/controllers/onboarding/`.

## ViewComponents

- **All UI is ViewComponent** — no ERB partials. ~140 components under `app/components/`.
- Each component is a directory: `component_name/component.rb` (+ optional `component.css`).
- Naming: snake_case directory, `ComponentName::Component` class.
- Test components in `spec/components/` using `ViewComponent::TestHelpers`.

## Service Objects

- Inherit `ApplicationService`. Implement `#call`. Class-level entry point: `MyService.call(...)`.
- Location: `app/services/`. Feature-grouped subdirectories are fine (e.g. `app/services/requests/`).
- `Lint/MissingSuper` is disabled for `app/services/**/*.rb` — no need for `super` in initializers.

## Background Jobs

- Use `Delayed::Job` via `delay` on model instances for deferred execution (e.g. scheduled broadcasts).
- Active Job (`ApplicationJob`) for standard async jobs.
- Adapter-specific jobs live in `app/jobs/<adapter>/`.

## JavaScript & CSS

- **Stimulus** for interactive components. Controllers in `app/assets/javascript/`.
- **Turbo** for navigation and form submissions.
- **PostCSS** for CSS (preset-env + easy-import + cssnano). Source: `app/assets/stylesheets/`.
- Build: `npm run build` (one-shot) or `npm run dev` (watch). Output: `app/assets/builds/`.
- Formatting: Prettier enforced on `app/**/!(build)/*.{js,css}`. Run `npm run prettier:fix` to auto-fix.

## Internationalization

- Locale files under `config/locales/`. Default locale inferred from context — Faker uses `:de` in tests.
- Onboarding copy (page, success heading/text) loaded from `config/locales/onboarding/` and stored on `Organization`.

## Guards

- `app/guards/` — authorization guard objects (e.g. `MustResetPasswordGuard`). Called from controllers to enforce access rules before action execution.
