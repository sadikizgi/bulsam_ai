require 'sidekiq/web'

Rails.application.routes.draw do
  # Sidekiq Web UI
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  # Devise routes
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Root path definitions
  root 'home#index'

  # Dashboard routes
  get 'dashboard', to: 'dashboard#index', as: :dashboard
  
  # Car tracking routes
  resources :cars do
    member do
      post 'start_tracking'
      post 'stop_tracking'
    end
  end
  
  # Property tracking routes
  resources :properties do
    member do
      post 'start_tracking'
      post 'stop_tracking'
    end
  end

  # Authentication based routes
  authenticated :user do
    # Özel rotalar eklenebilir
  end

  # Home controller routes
  get 'home', to: 'home#index'
end