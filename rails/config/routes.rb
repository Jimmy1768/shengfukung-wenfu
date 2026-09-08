Rails.application.routes.draw do
  # --- Health & root redirects ------------------------------------------------
  get "up" => "rails/health#show", as: :rails_health_check
  root to: redirect("/marketing/admin")

  # --- Public API -------------------------------------------------------------
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :demo_contacts, only: :create
      post "temple/contact_temple_requests", to: "contact_temple_requests#create"
      post "payments/webhooks/:provider", to: "payment_webhooks#create", as: :payment_webhook
      post "platform_billing/webhooks", to: "platform_billing_webhooks#create", as: :platform_billing_webhook
      get "temple", to: "temples#show"
      get "temple/news", to: "temple_news#index"
      get "temple/archive", to: "temple_galleries#index"
      get "temple/events", to: "temple_events#index"
      get "temple/events/:event_slug", to: "temple_events#show"
      get "temple/services", to: "temple_services#index"
      get "temple/services/:service_slug", to: "temple_services#show"
      get "temple/gatherings", to: "temple_gatherings#index"

      namespace :account do
        resources :registrations, only: :index
        resources :payment_statuses, only: :show, param: :reference
        resources :certificates, only: :index
        resources :guest_lists, only: :show, param: :offering_id
        resource :preferences, only: %i[show update]

        # Native account sessions intentionally live beside, not inside, the
        # legacy cookie-authenticated account API above. This namespace never
        # exposes its payment-status or guest-list routes.
        scope :native, as: :native_account do
          post "signup", to: "native_sessions#signup"
          post "login", to: "native_sessions#login"
          post "refresh", to: "native_sessions#refresh"
          delete "logout", to: "native_sessions#logout"
          post "password/recovery", to: "native_sessions#password_recovery"
          post "password/reset", to: "native_sessions#password_reset"
          post "oauth/start", to: "native_oauth#start"
          post "oauth/exchange", to: "native_oauth#exchange"
          get "oauth/resolution", to: "native_oauth_resolutions#show"
          post "oauth/resolution/existing", to: "native_oauth_resolutions#existing"
          post "oauth/resolution/new", to: "native_oauth_resolutions#new_account"
          get "bootstrap", to: "native_bootstrap#show"
          resource :profile, controller: "native_profile", only: %i[show update] do
            post :password
          end
          resources :dependents, controller: "native_dependents", only: %i[index show create update destroy]
          resources :registrations, controller: "native_registrations", only: %i[index show new create edit update]
          resource :preferences, controller: "native_preferences", only: %i[show update]
          get "events", to: "native_resources#events"
          get "services", to: "native_resources#services"
          get "galleries", to: "native_resources#galleries"
          get "galleries/:id", to: "native_resources#galleries"
          get "certificates", to: "native_resources#certificates"
          post "assistance", to: "native_resources#assistance"
          post "contact", to: "native_resources#contact"
          get "privacy", to: "native_privacy#show"
          post "privacy/close", to: "native_privacy#close"
          post "privacy/:request_type", to: "native_privacy#request_action"
        end
      end
    end
  end

  namespace :payments, defaults: { format: :html } do
    get "ecpay_checkouts/:payment_reference", to: "ecpay_checkouts#show", as: :ecpay_checkout
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
    resources :offering_setup_drafts, path: "offering-setup" do
      member do
        post :submit
        post :review
        post :apply
      end
    end
    resources :events, controller: "events" do
      resources :offering_orders,
        path: "orders",
        controller: "offering_orders",
        defaults: { offering_kind: "events" },
        only: %i[index new create show edit update] do
        member { post :complete; post :fulfil }
        collection { post :complete_many }
      end
    end
    resources :services, controller: "services" do
      resources :offering_orders,
        path: "orders",
        controller: "offering_orders",
        defaults: { offering_kind: "services" },
        only: %i[index new create show edit update] do
        member { post :complete; post :fulfil }
        collection { post :complete_many }
      end
    end
    resources :gatherings, controller: "gatherings", except: :show do
      # Pressing 上傳 on an existing gathering saves the image then and there.
      # It used to only fill a form field, so the picture was not stored until
      # the admin scrolled down and pressed the page's Save -- and if they did
      # not, it was lost without a word.
      member { patch :hero_image, action: :update_hero_image }
      resources :offering_orders,
        path: "orders",
        controller: "offering_orders",
        defaults: { offering_kind: "gatherings" },
        only: %i[index new create show edit update] do
        member { post :complete; post :fulfil }
        collection { post :complete_many }
      end
    end
    resources :registrations, only: :index
    resources :orders, only: :index
    resources :payments, only: %i[index new create] do
      collection do
        get :export
        post :start_checkout
        match :checkout_return, via: %i[get post]
      end
    end
    resource :payment_methods, only: %i[show update] do
      post :start_billing_setup
      get :billing_setup_return
    end
    resource :platform_billing, controller: "platform_billing", only: :show
    resources :assistance_requests, only: :index do
      member do
        post :close
      end
    end
    resources :news_posts
    resources :gallery_entries, except: :show
    resources :media_uploads, only: :create
    get "/archives", to: "archives#index", as: :archives
    get "/archives/registrations", to: "archives#registrations_export", defaults: { format: :csv }, as: :archive_registrations_export
    get "/archives/payments", to: "archives#payments_export", defaults: { format: :csv }, as: :archive_payments_export
    get "/archives/certificates", to: "archives#certificates_export", defaults: { format: :csv }, as: :archive_certificates_export
    resources :permissions, only: %i[index update], param: :admin_account_id
    resources :patrons, only: %i[index] do
      collection do
        get :oauth_duplicates
      end

      member do
        post :promote
        delete :revoke
        get :records
        patch :note
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
    resources :privacy_requests, only: :index do
      member do
        get :export
        post :transition
      end
    end
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
    # QR the TempleMate app scans to load this temple. The patron has already
    # joined on the web; this only tells the app which temple to bind to.
    get "/connect", to: "connections#show", as: :connect
    resource :settings, only: %i[show update], controller: "settings"
    resource :privacy, only: :show, controller: "privacy" do
      post :close
      post :request_data_deletion
      post :request_data_export
    end
    get "/oauth/identities", to: "oauth_identities#index", as: :oauth_identities
    post "/oauth/:provider/link", to: "oauth_identities#create", as: :oauth_link
    delete "/oauth/:provider/unlink", to: "oauth_identities#destroy", as: :oauth_unlink
    get "/oauth/resolution", to: "oauth_resolutions#show", as: :oauth_resolution
    post "/oauth/resolution/existing", to: "oauth_resolutions#existing", as: :oauth_resolution_existing
    post "/oauth/resolution/new", to: "oauth_resolutions#new_account", as: :oauth_resolution_new_account
    get "/oauth/consolidation", to: "oauth_consolidations#show", as: :oauth_consolidation
    post "/oauth/consolidation", to: "oauth_consolidations#create"
    resources :dependents, only: %i[new create edit update destroy]
    resources :registrations, only: %i[index show edit update new create] do
      member do
        get :payment
        post :start_checkout
        match :checkout_return, via: %i[get post]
      end
    end
    resources :events, only: :index
    resources :services, only: :index
    resources :galleries, only: %i[index show]
    resources :payments, only: :index
    resources :assistance_requests, only: :create
    resource :locale, only: :create, controller: "locales"
    resource :theme, only: :create, controller: "themes"
    resources :contact_temple_requests, only: :create

  end

  resource :password, controller: "utils/passwords", only: %i[new create edit]
  post "/password/reset", to: "utils/passwords#update", as: :password_update

# --- Central auth bridge ----------------------------------------------------
get "/auth/central/:provider/start", to: "auth/central_oauth#start", as: :central_oauth_start
match "/auth/callback", to: "auth/central_oauth#callback", via: %i[get post], as: :central_oauth_callback

  # --- OmniAuth callbacks -----------------------------------------------------
  match "/auth/:provider/callback", to: "auth/omniauth#callback", via: %i[get post]
  match "/auth/failure", to: "auth/omniauth#failure", via: %i[get post]

end
