# frozen_string_literal: true

Rails.application.routes.draw do
  mount Facebook::Messenger::Server, at: 'facebook-bot'

  root to: redirect('/dashboard')
  get '/dashboard', to: 'dashboard#index'
  get '/search', to: 'search#index'
  telegram_webhook Telegram::WebhookController, Rails.configuration.bot_id

  resources :requests, only: %i[index show new create]

  resources :users, except: :edit do
    resources :requests, only: %i[show], to: 'requests#show_user_messages'

    member do
      post 'message'
    end
  end

  resources :messages do
    member do
      post 'highlight', format: /json/
    end
  end
end
