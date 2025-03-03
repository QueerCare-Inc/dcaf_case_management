Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions' },
             skip: [:registrations]
  authenticate :user do
    root to: 'dashboards#index', as: :authenticated_root
    get 'dashboard', to: 'dashboards#index', as: 'dashboard'
    post 'search', to: 'dashboards#search', defaults: { format: :js }

    # For call list management
    patch 'call_lists/reorder_call_list', to: 'call_lists#reorder_call_list', as: 'reorder_call_list', defaults: { format: :js }
    patch 'call_lists/clear_current_user_call_list', to: 'call_lists#clear_current_user_call_list', as: 'clear_current_user_call_list', defaults: { format: :js }
    patch 'call_lists/add_patient/:id', to: 'call_lists#add_patient', as: 'add_patient', defaults: { format: :js }
    patch 'call_lists/remove_patient/:id', to: 'call_lists#remove_patient', as: 'remove_patient', defaults: { format: :js }

    # User REST routes and searching
    post 'users/search', to: 'users#search', as: 'users_search', defaults: { format: :js }
    resources :users, only: [:new, :create, :index, :edit, :update]

    # For user management
    patch 'users/:id/change_role_to_admin', to: 'users#change_role_to_admin', as: 'change_role_to_admin'
    patch 'users/:id/change_role_to_data_volunteer', to: 'users#change_role_to_data_volunteer', as: 'change_role_to_data_volunteer'
    patch 'users/:id/change_role_to_cm', to: 'users#change_role_to_cm', as: 'change_role_to_cm'
    patch 'users/:id/change_role_to_cr', to: 'users#change_role_to_cr', as: 'change_role_to_cr'
    patch 'users/:id/change_role_to_volunteer', to: 'users#change_role_to_volunteer', as: 'change_role_to_volunteer'
    post 'users/:id/toggle_disabled', to: 'users#toggle_disabled', as: 'toggle_disabled'

    # Patient routes
    # /patients/:id/edit
    # /patients/:id/calls
    # /patients/:id/notes
    # /patients/:id/practical_supports
    resources :patients,
              only: [ :create, :edit, :update, :index, :destroy ] do
      resources :calls,
                only: [ :create, :destroy, :new ]
      resources :notes,
                only: [ :create, :update ]
      resources :practical_supports,
                only: [ :create, :edit, :update, :destroy ]      
    end

    # For practical support notes
    resources :practical_support, only: [] do
      resources :notes,
                only: [ :create, :update ]
    end

    get 'data_entry', to: 'patients#data_entry', as: 'data_entry' # temporary
    post 'data_entry', to: 'patients#data_entry_create', as: 'data_entry_create' # temporary

    resources :accountants, only: [:index, :edit]

    resources :regions, only: [:new, :create]
    post 'clinicfinder', to: 'clinicfinders#search', defaults: { format: :js }, as: 'clinicfinder_search'
    resources :clinics, only: [:index, :create, :update, :new, :destroy, :edit]
    resources :configs, only: [:index, :create, :update]
    resources :events, only: [:index]

    resources :auth_factors, only: [:new, :destroy]
    resources :build_auth_factor, only: [:show, :update], controller: 'auth_factor_steps'
  end

  resources :multi_factor_authentication, only: [:show, :update]

  # Auth routes
  root :to => redirect('/users/sign_in')
  as :user do
    get '/users/edit' => 'users/registrations#edit', as: 'edit_user_registration'
    put '/users' => 'users/registrations#update', as: 'registration'
  end

  match '/404' => 'errors#error_404', via: [:get, :post, :put, :patch]
  match '/422' => 'errors#error_422', via: [:get, :post, :put, :patch]
  match '/500' => 'errors#error_500', via: [:get, :post, :put, :patch]
end
