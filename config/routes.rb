require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  get "settings/index"
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  
  root 'home#index'
  
  get 'dashboard', to: 'dashboard#index'
  get 'notifications', to: 'notifications#index', as: :notifications
  get 'settings', to: 'settings#index'
  
  resources :cars, only: [:index, :create, :destroy]
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
  
  resources :cars do
    member do
      get 'features'
      put 'features', to: 'cars#update_features'
      get 'sort_scrapes'
    end
  end
  
  resources :properties do
    member do
      get :features
      patch :update_features
      get :sort_scrapes
    end
  end
end