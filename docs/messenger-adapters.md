---
title: Messenger Adapters
summary: How inbound and outbound adapters work for each channel, and how contributors onboard.
read_when:
  - working on a channel-specific feature (Signal, Telegram, WhatsApp, Threema, email)
  - debugging message delivery or inbound webhook handling
  - adding a new channel
---

# Messenger Adapters

100eyes supports five messaging channels: **Signal**, **Telegram**, **WhatsApp** (360dialog), **Threema**, and **Email** (Postmark). Each lives under `app/adapters/<channel>_adapter/`.

## Structure

Every adapter follows the same two-file pattern:

```
app/adapters/<channel>_adapter/
  inbound.rb      # receives webhook, creates Message
  outbound.rb     # sends Message to contributor
  outbound/       # subclasses/helpers for outbound sending
```

Signal additionally has `api.rb` for its REST client and several error classes.

## Inbound Flow

Webhooks POST to channel-specific controllers (e.g. `whats_app/three_sixty_dialog_webhook#message`, `telegram/*`, `signal/*`). The controller delegates to the inbound adapter, which:

1. Identifies the organization from the webhook payload.
2. Finds or raises on unknown contributor.
3. Builds a `Message` with `sender_type: 'Contributor'` and persists it.
4. Attaches raw webhook payload as `raw_data` (required for contributor-sent messages).

## Outbound Flow

`Message#send!` calls `send!(message)` on every outbound adapter class. Each adapter checks whether it handles the message (e.g. contributor has a Telegram ID, org has a Telegram bot key). Unhandled messages are silently skipped.

Outbound adapters are:
- `PostmarkAdapter::Outbound`
- `SignalAdapter::Outbound`
- `TelegramAdapter::Outbound`
- `ThreemaAdapter::Outbound`
- `WhatsAppAdapter::ThreeSixtyDialogOutbound`

## Channel Configuration (on Organization)

Each channel requires credentials on the `Organization` record (encrypted via `attr_encrypted`):

| Channel | Required fields |
|---------|----------------|
| Telegram | `telegram_bot_api_key`, `telegram_bot_username` |
| WhatsApp | `three_sixty_dialog_client_api_key` |
| Threema | `threemarb_api_identity`, `threemarb_api_secret`, `threemarb_private` |
| Signal | `signal_server_phone_number`, `signal_username` |
| Email | `email_from_address` + `POSTMARK_API_TOKEN` env var |

`Organization#channels_onboarding_allowed` returns which channels have valid config and are toggled on via `onboarding_allowed`.

## Onboarding Flow

Contributors self-onboard at `/:organization_id/onboarding/<channel>`. Each channel has a dedicated controller under `app/controllers/onboarding/`. The flow:

1. Contributor lands on onboarding page, selects channel.
2. Channel-specific form collects contact info (email, phone number, Telegram link click, etc.).
3. On submit, a `Contributor` record is created and a welcome message sent via the chosen channel.
4. Contributor is redirected to the success page.

Telegram onboarding uses a deep-link token (`telegram_onboarding_token`) that links the browser session to the Telegram chat. Signal onboarding works differently: the contributor is shown an 8-character onboarding token on the web form; they must send that token as their first Signal message to the org's Signal number. The incoming webhook payload contains their `sourceUuid` — the system looks up the contributor by matching the message text against `signal_onboarding_token`, then saves the UUID to that contributor record and sends a welcome message.
