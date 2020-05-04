# frozen_string_literal: true

BOT_ID = (ENV['BOT'] || :default).to_sym

Rails.application.routes.draw do
  root to: redirect('/dashboard')
  telegram_webhook Telegram::WebhookController, BOT_ID
  resources :requests, only: %i[new create]
  get 'pending/not_implemented'
  get 'dashboard', to: 'dashboard#index'
  resources :users, only: %i[index edit update destroy show] do
    resources :requests, only: %i[show]
  end
end
