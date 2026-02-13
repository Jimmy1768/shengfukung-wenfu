Rails.application.routes.draw do
  # --- Health & root redirects ------------------------------------------------
  get "up" => "rails/health#show", as: :rails_health_check
  root to: redirect("/marketing/admin")

  # --- Public API -------------------------------------------------------------
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :demo_contacts, only: :create
      resources :temples, only: :show, param: :slug
      get "temples/:slug/news", to: "temple_news#index"
      get "temples/:slug/archive", to: "temple_galleries#index"
      get "temples/:slug/events", to: "temple_events#index"
      get "temples/:slug/events/:event_slug", to: "temple_events#show"
      get "temples/:slug/services", to: "temple_services#index"
      get "temples/:slug/services/:service_slug", to: "temple_services#show"
      get "temples/:slug/gatherings", to: "temple_gatherings#index"
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
  namespace :admin, defaults: { format: :html } do
    get "/", to: redirect("/admin/dashboard")
    get "/login", to: "sessions#new", as: :login
    post "/login", to: "sessions#create", as: :sessions
    match "/logout", to: "sessions#destroy", via: %i[delete post], as: :logout

    get "/dashboard", to: "dashboard#index", as: :dashboard
    get "/temple/profile", to: "temples#edit", as: :temple_profile
    match "/temple/profile", to: "temples#update", via: %i[patch post]

    resources :offerings, only: %i[index new create]
    resources :events, controller: "events" do
      resources :offering_orders,
        path: "orders",
        controller: "offering_orders",
        defaults: { offering_kind: "events" },
        only: %i[index new create show]
    end
    resources :services, controller: "services" do
      resources :offering_orders,
        path: "orders",
        controller: "offering_orders",
        defaults: { offering_kind: "services" },
        only: %i[index new create show]
    end
    resources :gatherings, controller: "gatherings", except: :show do
      resources :offering_orders,
        path: "orders",
        controller: "offering_orders",
        defaults: { offering_kind: "gatherings" },
        only: %i[index new create show]
    end
    resources :orders, only: :index
    resources :payments, only: %i[index new create] do
      collection do
        get :export
      end
    end
    resources :news_posts
    resources :gallery_entries
    resources :media_uploads, only: :create
    get "/archives", to: "archives#index", as: :archives
    get "/archives/registrations", to: "archives#registrations_export", defaults: { format: :csv }, as: :archive_registrations_export
    get "/archives/payments", to: "archives#payments_export", defaults: { format: :csv }, as: :archive_payments_export
    get "/archives/certificates", to: "archives#certificates_export", defaults: { format: :csv }, as: :archive_certificates_export
    resources :permissions, only: %i[index update], param: :admin_account_id
    resources :patrons, only: %i[index create] do
      member do
        post :promote
        delete :revoke
        get :records
      end

      resources :metadata_values, only: %i[create destroy], controller: "patron_metadata_values"
    end
    resource :temple_switch, only: :create, controller: "temple_switches"
    resource :locale, only: :create, controller: "locales"
  end

  # --- User account console --------------------------------------------------
  namespace :account, defaults: { format: :html } do
    get "/", to: redirect("/account/dashboard")
    get "/login", to: "sessions#new", as: :login
    post "/login", to: "sessions#create", as: :sessions
    match "/logout", to: "sessions#destroy", via: %i[delete post], as: :logout
    get "/register", to: "signups#new", as: :register
    post "/register", to: "signups#create"
    resources :temples, only: :index

    get "/dashboard", to: "dashboard#index", as: :dashboard
    resource :profile, only: %i[show edit update], controller: "profile"
    resources :dependents, except: :show
    resources :registrations, only: %i[index show edit update new create] do
      member do
        get :payment
      end
    end
    resources :events, only: :index
    resources :services, only: :index
    resources :galleries, only: %i[index show]
    resources :payments, only: :index
    resource :locale, only: :create, controller: "locales"

    namespace :api, defaults: { format: :json } do
      resources :registrations, only: :index
      resources :payment_statuses, only: :show, param: :reference
      resources :certificates, only: :index
      resources :guest_lists, only: :show, param: :offering_id
    end
  end

  resource :password, controller: "utils/passwords", only: %i[new create edit]
  post "/password/reset", to: "utils/passwords#update", as: :password_update

  namespace :utils do
    resources :uploads, only: :create
  end

  # --- OmniAuth callbacks -----------------------------------------------------
  match "/auth/:provider/callback", to: "auth/omniauth#callback", via: %i[get post]
  match "/auth/failure", to: "auth/omniauth#failure", via: %i[get post]

  if Rails.env.development?
    namespace :dev do
      resource :theme, only: :create, controller: "theme_previews"
    end
  end
end
