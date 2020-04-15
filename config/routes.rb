# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/dashboard')
  telegram_webhook Telegram::WebhookController
  get 'pending/not_implemented'
  get 'dashboard', to: 'dashboard#index'
  resources :questions, only: %i[new create]
end
