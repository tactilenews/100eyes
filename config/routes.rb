# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/dashboard')
  get 'pending/not_implemented'
  get '/dashboard', to: 'dashboard#index'
  get '/search', to: 'search#index'
  telegram_webhook Telegram::WebhookController, Rails.configuration.bot_id

  resources :requests, only: %i[index show new create]

  resources :users, only: %i[index show update destroy] do
    resources :requests, only: %i[show], to: 'requests#show_user_messages'
  end
end
