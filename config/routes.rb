# frozen_string_literal: true

Rails.application.routes.draw do
  telegram_webhook Telegram::WebhookController
  root to: redirect('/requests/new')
  resources :requests, only: %i[new create]
end
