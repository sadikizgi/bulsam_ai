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
end