Rails.application.routes.draw do
  # --- Health & root redirects ------------------------------------------------
  get "up" => "rails/health#show", as: :rails_health_check
  root to: redirect("/marketing/admin")

  # --- Public API -------------------------------------------------------------
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :demo_contacts, only: :create
      post "temples/:slug/contact_temple_requests", to: "contact_temple_requests#create"
      post "payments/webhooks/:provider", to: "payment_webhooks#create", as: :payment_webhook
      resources :temples, only: :show, param: :slug
      get "temples/:slug/news", to: "temple_news#index"
      get "temples/:slug/archive", to: "temple_galleries#index"
      get "temples/:slug/events", to: "temple_events#index"
      get "temples/:slug/events/:event_slug", to: "temple_events#show"
      get "temples/:slug/services", to: "temple_services#index"
      get "temples/:slug/services/:service_slug", to: "temple_services#show"
      get "temples/:slug/gatherings", to: "temple_gatherings#index"

      namespace :account do
        resources :registrations, only: :index
        resources :payment_statuses, only: :show, param: :reference
        resources :certificates, only: :index
        resources :guest_lists, only: :show, param: :offering_id
        resource :preferences, only: %i[show update]
      end
    end
  end

  # --- Marketing admin showcase ----------------------------------------------
  namespace :marketing_admin, path: "/marketing/admin", module: "demo" do
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
        only: %i[index new create show edit update]
    end
    resources :services, controller: "services" do
      resources :offering_orders,
        path: "orders",
        controller: "offering_orders",
        defaults: { offering_kind: "services" },
        only: %i[index new create show edit update]
    end
    resources :gatherings, controller: "gatherings", except: :show do
      resources :offering_orders,
        path: "orders",
        controller: "offering_orders",
        defaults: { offering_kind: "gatherings" },
        only: %i[index new create show edit update]
    end
    resources :registrations, only: :index
    resources :orders, only: :index
    resources :payments, only: %i[index new create] do
      collection do
        get :export
        post :fake_checkout
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
      collection do
        get :oauth_duplicates
      end

      member do
        post :promote
        delete :revoke
        get :records
      end

      resources :metadata_values, only: %i[create destroy], controller: "patron_metadata_values"
    end
    resource :temple_switch, only: :create, controller: "temple_switches"
    resource :locale, only: :create, controller: "locales"
    resource :theme, only: :create, controller: "themes"
  end

  namespace :internal, defaults: { format: :html } do
    get "/temples/access", to: "temple_access#index", as: :temple_access
    get "/temples/access/:temple_id", to: "temple_access#show", as: :temple_access_temple
    post "/temples/access/:temple_id/grant", to: "temple_access#grant", as: :grant_temple_access
    post "/temples/access/:temple_id/admins/:admin_account_id/owner",
      to: "temple_access#promote_owner",
      as: :promote_temple_access_owner
    delete "/temples/access/:temple_id/revoke", to: "temple_access#revoke", as: :revoke_temple_access
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
    resource :settings, only: %i[show update], controller: "settings"
    get "/oauth/identities", to: "oauth_identities#index", as: :oauth_identities
    post "/oauth/:provider/link", to: "oauth_identities#create", as: :oauth_link
    delete "/oauth/:provider/unlink", to: "oauth_identities#destroy", as: :oauth_unlink
    resources :dependents, only: %i[new create edit update destroy]
    resources :registrations, only: %i[index show edit update new create] do
      member do
        get :payment
        post :start_fake_checkout
      end
    end
    resources :events, only: :index
    resources :services, only: :index
    resources :galleries, only: %i[index show]
    resources :payments, only: :index
    resource :locale, only: :create, controller: "locales"
    resource :theme, only: :create, controller: "themes"
    resources :contact_temple_requests, only: :create

  end

  resource :password, controller: "utils/passwords", only: %i[new create edit]
  post "/password/reset", to: "utils/passwords#update", as: :password_update

  namespace :utils do
    resources :uploads, only: :create
  end

# --- Central auth bridge ----------------------------------------------------
get "/auth/central/:provider/start", to: "auth/central_oauth#start", as: :central_oauth_start
match "/auth/callback", to: "auth/central_oauth#callback", via: %i[get post], as: :central_oauth_callback

  # --- OmniAuth callbacks -----------------------------------------------------
  match "/auth/:provider/callback", to: "auth/omniauth#callback", via: %i[get post]
  match "/auth/failure", to: "auth/omniauth#failure", via: %i[get post]

end
