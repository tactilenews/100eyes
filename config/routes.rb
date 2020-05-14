# frozen_string_literal: true

Rails.application.routes.draw do
  get '/search', to: 'search#index'
  root to: redirect('/dashboard')
  telegram_webhook Telegram::WebhookController, Rails.configuration.bot_id
  resources :requests, only: %i[new create]
  get 'pending/not_implemented'
  get 'dashboard', to: 'dashboard#index'
  resources :users, only: %i[index edit update destroy show] do
    resources :requests, only: %i[show]
  end
end
