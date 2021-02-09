# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/dashboard')
  get '/dashboard', to: 'dashboard#index'
  get '/search', to: 'search#index'
  get '/health', to: 'health#index'

  get '/onboarding', to: 'onboarding#index'
  get '/onboarding/success', to: 'onboarding#success'

  namespace :onboarding do
    post '/email', to: 'email#create'
    get '/telegram', to: 'telegram#create'
    patch '/telegram', to: 'telegram#update'
    get '/telegram/info', to: 'telegram#info'
  end

  get '/settings', to: 'settings#index'
  post '/settings', to: 'settings#update'

  namespace :threema do
    post '/webhook', to: 'webhook#message'
  end

  telegram_webhook Telegram::WebhookController

  resources :requests, only: %i[index show new create] do
    member do
      get 'notifications', format: /json/
    end
  end

  resources :contributors, except: :edit do
    resources :requests, only: %i[show], to: 'requests#show_contributor_messages'

    member do
      post 'message'
    end

    collection do
      get 'count'
    end
  end

  resources :invites, only: :create

  resources :messages, only: %() do
    member do
      scope module: :messages, as: :message do
        resource :highlight, only: :update, format: /json/
        resource :request, only: %i[show update]
      end
    end
  end

  namespace :user, only: %i[two_factor_auth_setup] do
    resources :settings do
      member do
        get '/two_factor_auth_setup', to: 'settings#two_factor_auth_setup'
        patch '/two_factor_auth_setup', to: 'settings#enable_otp'
      end
    end
  end

  # Clearance routes

  resources :passwords,
            controller: 'passwords',
            only: %i[create new]

  resource :session,
           controller: 'sessions',
           only: :create

  resources :users,
            only: Clearance.configuration.user_actions do
    resource :password,
             controller: 'passwords',
             only: %i[edit update]
  end

  get '/sign_in' => 'sessions#new', as: 'sign_in'
  delete '/sign_out' => 'sessions#destroy', as: 'sign_out'
end
