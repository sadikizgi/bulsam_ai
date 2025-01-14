require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  
  root 'home#index'
  
  get 'dashboard', to: 'dashboard#index'
  
  resources :cars, only: [:index, :show]
  resources :properties, only: [:index, :show]
  
  # Sidekiq Web UI
  require 'sidekiq/web'
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end
  
  # API endpoints for vehicle selection
  namespace :api do
    resources :categories, only: [] do
      resources :brands, only: [:index]
    end
    
    resources :brands, only: [] do
      resources :models, only: [:index]
    end
    
    resources :models, only: [] do
      resources :serials, only: [:index]
    end
  end
end