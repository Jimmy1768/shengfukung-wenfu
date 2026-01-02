Rails.application.routes.draw do
  # --- Health & root redirects ------------------------------------------------
  get "up" => "rails/health#show", as: :rails_health_check
  root to: redirect("/marketing/admin")

  # --- Public API -------------------------------------------------------------
  namespace :api do
    namespace :v1 do
      resources :demo_contacts, only: :create
      resources :temples, only: :show, param: :slug
    end
  end

  # --- Marketing admin showcase ----------------------------------------------
namespace :marketing_admin, path: "/marketing/admin", module: "dev/demo/rails" do
    # Auth + sessions
    get "/", to: "sessions#new", as: :login
    post "/", to: "sessions#create", as: :sessions
    match "/logout", to: "sessions#destroy", via: %i[delete post], as: :logout

    # Demo dashboards
    get "/dashboard", to: "dashboard#index", as: :dashboard
    get "/app_messages", to: "app_messages#index", as: :app_messages
    get "/users", to: "users#index", as: :users
    get "/playground", to: "playground#show", as: :playground
  end

  # --- Real admin console ----------------------------------------------------
  namespace :admin do
    get "/", to: redirect("/admin/dashboard")
    get "/login", to: "sessions#new", as: :login
    post "/login", to: "sessions#create", as: :sessions
    match "/logout", to: "sessions#destroy", via: %i[delete post], as: :logout

    get "/dashboard", to: "dashboard#index", as: :dashboard
    get "/temple/profile", to: "temples#edit", as: :temple_profile
    patch "/temple/profile", to: "temples#update"
  end

  # --- User account console --------------------------------------------------
  namespace :account do
    get "/", to: redirect("/account/dashboard")
    get "/login", to: "sessions#new", as: :login
    post "/login", to: "sessions#create", as: :sessions
    match "/logout", to: "sessions#destroy", via: %i[delete post], as: :logout
    get "/register", to: "registrations#new", as: :register
    post "/register", to: "registrations#create"

    get "/dashboard", to: "dashboard#index", as: :dashboard
  end

  resource :password, controller: "utils/passwords", only: %i[new create edit]
  post "/password/reset", to: "utils/passwords#update", as: :password_update

  # --- OmniAuth callbacks -----------------------------------------------------
  match "/auth/:provider/callback", to: "auth/omniauth#callback", via: %i[get post]
  match "/auth/failure", to: "auth/omniauth#failure", via: %i[get post]
end
