# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/dashboard')
  get '/dashboard', to: 'dashboard#index'
  get '/search', to: 'search#index'
  get '/health', to: 'health#index'

  get '/onboarding', to: 'onboarding#index'
  get '/onboarding/success', to: 'onboarding#success'
  post '/onboarding/invite', to: 'onboarding#create_invite_url'

  namespace :onboarding do
    post '/', to: 'email#create'
    get '/telegram', to: 'telegram#telegram'
    patch '/telegram-update-info', to: 'telegram#telegram_update_info'
    get '/telegram-explained', to: 'telegram#telegram_explained'
  end

  get '/settings', to: 'settings#index'
  post '/settings', to: 'settings#update'

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

  resources :messages do
    member do
      post 'highlight', format: /json/
    end
  end

  namespace :user, only: %i[two_factor_auth_setup verify_user_otp] do
    resources :settings do
      member do
        get '/two_factor_auth_setup', to: 'settings#two_factor_auth_setup'
        patch '/enable_otp', to: 'settings#enable_otp'
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
