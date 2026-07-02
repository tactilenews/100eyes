---
title: Architecture Overview
summary: Core domain models, multi-tenancy pattern, and how the system fits together.
read_when:
  - starting a new feature and need to understand where it belongs
  - investigating an unfamiliar part of the codebase
---

# Architecture Overview

100eyes is a dialog-driven journalism platform built with Rails. Newsroom editors send questions ("requests") to a community of contributors via multiple messaging channels and collect their replies.

## Core Domain Models

| Model | Role |
|-------|------|
| `Organization` | A newsroom tenant. Owns all contributors, requests, and channel credentials. |
| `User` | A newsroom editor. Belongs to one or more organizations via `UsersOrganization`. Auth via Clearance + OTP. |
| `Contributor` | A community member who responds to requests. Has one or more channel identifiers (email, phone, Telegram ID, etc.). |
| `Request` | A question broadcast to contributors. Has a lifecycle: drafted → scheduled (`schedule_send_for`) → broadcasted (`broadcasted_at`). |
| `Message` | A single message in either direction. Polymorphic `sender` — either a `User` (outbound) or `Contributor` (reply/inbound). Belongs to an `Organization` and optionally a `Request`. |
| `BusinessPlan` | Feature flags / plan tiers attached to an organization. |
| `ActivityNotification` | In-app notifications; polymorphic recipient (User or Organization). |

## Multi-Tenancy

All resources are scoped to an `Organization`. Routes are prefixed with `/:organization_id`. There is no cross-org data access in normal flows. `PgSearch::Model` is used for full-text search with an `organization_id` filter baked into `additional_attributes`.

## Request Lifecycle

1. Editor creates a `Request` (title + text, optional file attachments).
2. `BroadcastRequestJob` sends outbound `Message` records to every active contributor via all configured adapters.
3. Contributors reply via their channel → inbound adapter creates a `Message` with `sender_type: 'Contributor'`.
4. Editor views replies grouped by contributor in the conversation view.

## Messenger Adapter Layer

Each channel has an adapter under `app/adapters/<channel>_adapter/`:

- **Inbound** (`inbound.rb`) — receives webhook payloads, finds/creates the contributor, persists the message.
- **Outbound** (`outbound.rb` + `outbound/`) — sends messages to contributors via the channel's API.

`Message#send!` iterates all outbound adapters; each adapter decides whether it handles the given message.

See `docs/messenger-adapters.md` for details.

## ViewComponents

UI is built with ViewComponent (`app/components/`). ~140 components. Each component has a `.rb` class and optional `.css`. No ERB partials for UI — always a component.

## Service Objects

`app/services/` contains service objects that inherit `ApplicationService`. Call interface: `MyService.call(...)`. Used for operations too complex for a model method.

## Background Jobs

Delayed Job (`delayed_job` gem) is used for background processing. Key jobs: `BroadcastRequestJob`, `MarkInactiveContributorInactiveJob`, `ResubscribeContributorJob`, `UnsubscribeContributorJob`. Adapter-specific jobs live under `app/jobs/<adapter>/`.

## Asset Pipeline

JS: esbuild via `bin/esbuild`. CSS: PostCSS. Both compiled to `app/assets/builds/`. Stimulus + Turbo for interactivity.
