Rails.application.routes.draw do
  # Root path tanımı (ana sayfa)
  root 'home#index'
  
  # Devise routes
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Dashboard route
  get 'dashboard', to: 'dashboard#index'

  # Giriş yapmış kullanıcılar için varsayılan rota
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  # Giriş yapmamış kullanıcılar için varsayılan rota
  unauthenticated do
    root "home#index", as: :unauthenticated_root
  end
end