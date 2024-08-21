# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/organizations')

  concern :paginatable do
    get '(page/:page)', action: :index, on: :collection, as: ''
  end
  post '/set-organization', to: 'organizations#set_organization'

  resources :organizations, only: :index

  scope ':organization_id', as: 'organization', constraints: { organization_id: /\d+/ } do
    # TODO: Move each unscoped controller here if it has to be scoped by its organization

    namespace :whats_app do
      get '/onboarding-successful', to: 'three_sixty_dialog_webhook#create_api_key'
      post '/three-sixty-dialog-webhook', to: 'three_sixty_dialog_webhook#message'
    end

    resources :invites, only: :create

    get '/search', to: 'search#index'
    get '/dashboard', to: 'dashboard#index'

    resources :requests, only: %i[index show new create edit update destroy], concerns: :paginatable do
      member do
        get 'notifications', format: /json/
        get 'messages-by-contributor'
        get 'stats'
      end
    end

    resources :messages, only: %i[new create edit update] do
      member do
        scope module: :messages, as: :message do
          resource :highlight, only: :update, format: /json/
          resource :request, only: %i[show update]
        end
      end
    end

    get '/settings', to: 'settings#index'
    patch '/settings', to: 'settings#update'

    namespace :onboarding, module: nil do
      get '/', to: 'onboarding#index'
      get '/success', to: 'onboarding#success'

      scope module: :onboarding do
        get '/email', to: 'email#show'
        post '/email', to: 'email#create'

        get '/signal/', to: 'signal#show'
        get '/signal/link/', to: 'signal#link', as: 'signal_link'
        post '/signal/', to: 'signal#create'

        get '/threema/', to: 'threema#show'
        post '/threema/', to: 'threema#create'

        get '/telegram/', to: 'telegram#show'
        get '/telegram/link/:telegram_onboarding_token', to: 'telegram#link', as: 'telegram_link'
        get '/telegram/fallback/:telegram_onboarding_token', to: 'telegram#fallback', as: 'telegram_fallback'
        post '/telegram/', to: 'telegram#create'

        get '/whats-app/', to: 'whats_app#show'
        post '/whats-app/', to: 'whats_app#create'
      end
    end

    namespace :charts do
      get 'day-and-time-replies'
      get 'day-and-time-requests'
      get 'day-requests-replies'
    end

    resources :contributors, only: %i[index show edit update], concerns: :paginatable do
      member do
        get 'conversations'
        post 'message'
      end

      collection do
        get 'count'
      end
    end
  end

  get '/health', to: 'health#index'
  get '/about', to: 'about#index'

  namespace :threema do
    post '/webhook', to: 'webhook#message'
  end

  namespace :whats_app do
    post '/webhook', to: 'webhook#message'
    post '/errors', to: 'webhook#errors'
    post '/status', to: 'webhook#status'
  end

  Telegram.bots.each do |(_name, bot)|
    telegram_webhook Telegram::WebhookController, bot, as: nil
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
      resources :stats, only: [:index]
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

  get '/profile', to: 'profile#index'
  post '/profile/user', to: 'profile#create_user'
  put '/profile/upgrade_business_plan', to: 'profile#upgrade_business_plan'
end
