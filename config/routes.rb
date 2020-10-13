# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/dashboard')
  get '/dashboard', to: 'dashboard#index'
  get '/search', to: 'search#index'
  get '/health', to: 'health#index'

  get '/onboarding', to: 'onboarding#index'
  post '/onboarding', to: 'onboarding#create'
  get '/onboarding/success', to: 'onboarding#success'


  resources :requests, only: %i[index show new create] do
    member do
      get 'notifications', format: /json/
    end
  end

  resources :users, except: :edit do
    resources :requests, only: %i[show], to: 'requests#show_user_messages'

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
end
