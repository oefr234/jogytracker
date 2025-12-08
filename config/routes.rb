Rails.application.routes.draw do
  root "dashboard#index"
  get "admin", to: "dashboard#admin"

  namespace :api do
    post "register", to: "registrations#create"
    post   "login",  to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    resources :users
    resources :time_entries
    get "reports/weekly", to: "reports#weekly"
  end

  get "login", to: "dashboard#login"
end
