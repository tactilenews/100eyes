# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/dashboard')
  telegram_webhook Telegram::WebhookController
  resources :requests, only: %i[new create]
  get 'pending/not_implemented'
  get 'dashboard', to: 'dashboard#index'
  resources :users, only: %i[index edit update destroy] do
    resources :requests, only: %i[show]
  end
end
