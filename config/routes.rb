# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/dashboard')
  get '/dashboard', to: 'dashboard#index'
  get '/search', to: 'search#index'
  get '/health', to: 'health#index'

  namespace :onboarding, module: nil do
    get '/', to: 'onboarding#index'
    get '/success', to: 'onboarding#success'

    scope module: :onboarding do
      get '/email', to: 'email#show'
      post '/email', to: 'email#create'

      get '/threema/', to: 'threema#show'
      post '/threema/', to: 'threema#create'

      get '/telegram/', to: 'telegram#show'
      post '/telegram/', to: 'telegram#create'
      get '/telegram/link/:telegram_onboarding_token', to: 'telegram#link', as: 'telegram_link'
      get '/telegram/fallback/:telegram_onboarding_token', to: 'telegram#fallback', as: 'telegram_fallback'
    end
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

  resources :messages, only: %i[new create edit update] do
    member do
      scope module: :messages, as: :message do
        resource :highlight, only: :update, format: /json/
        resource :request, only: %i[show update]
      end
    end
  end

  resource :session, controller: 'sessions', only: [:create]
  resources :passwords, controller: 'passwords', only: %i[create new]

  get '/sign_in' => 'sessions#new', as: 'sign_in'
  delete '/sign_out' => 'sessions#destroy', as: 'sign_out'

  resources :users, only: [] do
    resource :password do
      resource :password, controller: 'passwords', only: %i[edit update]
    end

    resources :settings do
      member do
        get '/two_factor_auth_setup', to: 'settings#two_factor_auth_setup'
        patch '/two_factor_auth_setup', to: 'settings#enable_otp'
      end
    end
  end

  namespace :otp do
    resource :confirmation, only: %i[new create]
    resource :setup, only: %i[new create]
  end

  namespace :admin do
    resources :users
    resources :contributors, except: %i[new create]
    resources :requests, except: %i[new create]

    root to: 'users#index'
  end
end
