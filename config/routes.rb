# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/dashboard')

  concern :paginatable do
    get '(page/:page)', action: :index, on: :collection, as: ''
  end

  get '/dashboard', to: 'dashboard#index'
  get '/search', to: 'search#index'
  get '/health', to: 'health#index'
  get '/about', to: 'about#index'

  namespace :onboarding, module: nil do
    get '/', to: 'onboarding#index'
    get '/success', to: 'onboarding#success'

    scope module: :onboarding do
      get '/email', to: 'email#show'
      post '/email', to: 'email#create'

      constraints(-> { Setting.signal_server_phone_number.present? }) do
        get '/signal/', to: 'signal#show'
        get '/signal/link/', to: 'signal#link', as: 'signal_link'
        post '/signal/', to: 'signal#create'
      end

      get '/threema/', to: 'threema#show'
      post '/threema/', to: 'threema#create'

      get '/telegram/', to: 'telegram#show'
      get '/telegram/link/:telegram_onboarding_token', to: 'telegram#link', as: 'telegram_link'
      get '/telegram/fallback/:telegram_onboarding_token', to: 'telegram#fallback', as: 'telegram_fallback'
      post '/telegram/', to: 'telegram#create'

      constraints(-> { Setting.whats_app_server_phone_number.present? || Setting.three_sixty_dialog_client_api_key.present? }) do
        get '/whats-app/', to: 'whats_app#show'
        post '/whats-app/', to: 'whats_app#create'
      end
    end
  end

  get '/settings', to: 'settings#index'
  post '/settings', to: 'settings#update'

  namespace :threema do
    post '/webhook', to: 'webhook#message'
  end

  namespace :whats_app do
    post '/webhook', to: 'webhook#message'
    post '/errors', to: 'webhook#errors'
    post '/status', to: 'webhook#status'
    get '/onboarding-successful', to: 'three_sixty_dialog_webhook#create_api_key'
    post '/three-sixty-dialog-webhook', to: 'three_sixty_dialog_webhook#message'
  end

  telegram_webhook Telegram::WebhookController

  resources :requests, only: %i[index show new create edit update destroy], concerns: :paginatable do
    member do
      get 'notifications', format: /json/
    end
  end

  resources :contributors, only: %i[index show edit update] do
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

  namespace :admin do
    constraints Clearance::Constraints::SignedIn.new(&:admin?) do
      root to: 'users#index'

      resources :users
      resources :contributors, only: %i[index show edit update destroy] do
        get :export, on: :collection
      end
      resources :requests, only: %i[index show destroy]
      resources :messages, only: %i[index show destroy]
      resources :delayed_jobs, only: %i[index show destroy]
      resources :business_plans, only: %i[index show edit update]
      resources :organizations, only: %i[index show edit update]
    end
  end

  resource :session, controller: 'sessions', only: %i[create]
  get '/sign_in' => 'sessions#new', as: 'sign_in'
  delete '/sign_out' => 'sessions#destroy', as: 'sign_out'

  resources :passwords, controller: 'passwords', only: %i[new create]

  resources :users, only: [] do
    resource :password, controller: 'passwords', only: %i[edit update]
  end

  resource :otp_setup, controller: :otp_setup, only: %i[show create]
  resource :otp_auth, controller: :otp_auth, only: %i[show create]

  namespace :charts do
    get 'day-and-time-replies'
    get 'day-and-time-requests'
    get 'day-requests-replies'
  end

  get '/profile', to: 'profile#index'
  post '/profile/user', to: 'profile#create_user'
  put '/profile/upgrade_business_plan', to: 'profile#upgrade_business_plan'

  get '/v1/contributors/me', to: 'api#show'
  post '/v1/contributors', to: 'api#create'
  put '/v1/contributors/me', to: 'api#update'
  get '/v1/contributors/me/requests/current', to: 'api#current_request'
  post '/v1/contributors/me/messages', to: 'api#messages'
  post '/v1/users/me/messages', to: 'api#direct_message'
end
