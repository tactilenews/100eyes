# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/users')
  get '/search', to: 'search#index'
  telegram_webhook Telegram::WebhookController, Rails.configuration.bot_id
  resources :requests, only: %i[new create]
  get 'pending/not_implemented'
  resources :users, only: %i[index edit update destroy show] do
    resources :requests, only: %i[show]
  end
end
