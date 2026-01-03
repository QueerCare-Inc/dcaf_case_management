Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions' },
             skip: [:registrations]
  authenticate :user do
    root to: 'dashboards#index', as: :authenticated_root
    get 'dashboard', to: 'dashboards#index', as: 'dashboard'
    post 'search', to: 'dashboards#search', defaults: { format: :js }

    # TEST
    resources :new_patient_forms, :new_care_address_forms

    ########

    # # For procedure management
    # patch 'procedure_lists/reorder_procedure_list', to: 'procedure_lists#reorder_procedure_list', as: 'reorder_procedure_list', defaults: { format: :js }
    # # patch 'procedure_lists/clear_current_user_procedure_list', to: 'procedure_lists#clear_current_user_procedure_list', as: 'clear_current_user_procedure_list', defaults: { format: :js }
    # patch 'procedure_lists/add_procedure/:id', to: 'procedure_lists#add_procedure', as: 'add_procedure', defaults: { format: :js }
    # patch 'procedure_lists/remove_procedure/:id', to: 'procedure_lists#remove_procedure', as: 'remove_procedure', defaults: { format: :js }

    # For care request management
    patch 'care_request_lists/reorder_care_request_list', to: 'care_request_lists#reorder_care_request_list', as: 'reorder_care_request_list', defaults: { format: :js }
    # patch 'care_request_lists/clear_current_user_care_request_list', to: 'care_request_lists#clear_current_user_care_request_list', as: 'clear_current_user_care_request_list', defaults: { format: :js }
    patch 'care_request_lists/add_care_request/:id', to: 'care_request_lists#add_care_request', as: 'add_care_request', defaults: { format: :js }
    patch 'care_request_lists/remove_care_request/:id', to: 'care_request_lists#remove_care_request', as: 'remove_care_request', defaults: { format: :js }


    # User REST routes and searching
    post 'users/search', to: 'users#search', as: 'users_search', defaults: { format: :js }

    # make sure that procedures are nested for index, create, and new
    # Users have one Person
    resources :users, only: [:new, :create, :index, :edit, :update, :show] do
      resource :person, only: [:show, :edit, :update] do
        # People can be one of: Patient, Care Coordinator, or Volunteer
        resource :patient, only: [:show, :edit, :update] do
          # Patients have many Notes
          resources :notes, only: [ :create, :update ]
          # Patients have many Procedures
          resources :procedures, only: [:index, :show, :new, :create, :edit, :update, :destroy], shallow: true do
            post :generate_shifts, on: :member, to: 'procedures#generate_shifts', as: 'generate_shifts'
            resources :shifts, only: [:new, :create]
            # Procedures have many Care Addresses
            resources :care_addresses, only: [:index, :new, :create, :edit, :update, :destroy] do
              # Care Addresses have many Shifts
              resources :shifts, only: [:new, :create, :edit, :update, :destroy, :index]
            end
            # Procedures have many Reimbursements
            # resources :reimbursements, only: [:new, :create, :edit, :update, :destroy]
          end

          # care addresses can be searched and added to a procedure
          resources :procedures, shallow: true do
            member do
              post :search_care_address, to: 'procedures#search_care_address', as: 'search_care_address', defaults: { format: :js } 
              patch :add_care_address, to: 'procedures#add_care_address', as: 'add_care_address' 
              post :select_care_address, to: 'procedures#select_care_address', as: 'select_care_address', defaults: { format: :js }
              post :add_shift
            end
          end
        end

        resource :care_coordinator, only: [:show, :edit, :update]
        resource :volunteer, only: [:show, :edit, :update] do
          # # Volunteers have many Shifts
          # resources :shifts, only: [:edit, :update, :destroy, :index]
          # Volunteers have many Notes
          resources :notes, only: [ :create, :update ]
        end
      end
    end    

    # Calendar resources
    resources :dashboards do
      get :week, on: :collection
    end

    # For user management
    patch 'users/:id/change_role_to_admin', to: 'users#change_role_to_admin', as: 'change_role_to_admin'
    patch 'users/:id/change_role_to_data_volunteer', to: 'users#change_role_to_data_volunteer', as: 'change_role_to_data_volunteer'
    patch 'users/:id/change_role_to_care_coordinator', to: 'users#change_role_to_care_coordinator', as: 'change_role_to_care_coordinator'
    patch 'users/:id/change_role_to_cr', to: 'users#change_role_to_cr', as: 'change_role_to_cr'
    patch 'users/:id/change_role_to_volunteer', to: 'users#change_role_to_volunteer', as: 'change_role_to_volunteer'
    patch 'users/:id/change_role_to_finance_admin', to: 'users#change_role_to_finance_admin', as: 'change_role_to_finance_admin'
    patch 'users/:id/change_role_to_coord_admin', to: 'users#change_role_to_coord_admin', as: 'change_role_to_coord_admin'
    post 'users/:id/toggle_disabled', to: 'users#toggle_disabled', as: 'toggle_disabled'

    # Patient routes
    # /patients/:id/edit
    # /patients/:id/calls
    # /patients/:id/notes
    # /patients/:id/practical_supports
    resources :patients,
              only: [ :create, :edit, :update, :index, :destroy ] do
      resources :care_requests,
                only: [ :create, :destroy, :new ]
      resources :notes,
                only: [ :create, :update ]  
    end
    patch '/update_patient_and_person', to: 'patients#update_patient_and_person', as: 'update_patient_and_person'
    patch '/update_user_patient_and_procedure', to: 'patients#update_user_patient_and_procedure', as: 'update_user_patient_and_procedure'
    patch '/update_practical_support', to: 'procedures#update_practical_support', as: 'update_practical_support'
    
    resources :care_request_entries, only: [ :index, :create, :update, :destroy ] do
      patch :update_care_coordinator, on: :member
      patch :mark_intake_complete, on: :member
      patch :mark_accepted, on: :member
      patch :mark_procedure_confirmed, on: :member
      patch :mark_under_care, on: :member
    end
    
    
    get 'data_entry', to: 'patients#data_entry', as: 'data_entry' # temporary
    post 'data_entry', to: 'patients#data_entry_create', as: 'data_entry_create' # temporary

    # resources :accountants, only: [:index, :edit]

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




  get '/favicon.ico', to: ->(_) { [204, {}, []] } # REMOVE BEFORE PRODUCTION

  match '*path', to: ->(env) { Rails.logger.debug "Matched route: #{env['REQUEST_METHOD']} #{env['PATH_INFO']}" }, via: :all
end
