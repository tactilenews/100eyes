# frozen_string_literal: true

Rails.application.routes.draw do
  telegram_webhook Telegram::WebhookController
  root to: redirect('/questions/new')
  resources :questions, only: %i[new create]
end
