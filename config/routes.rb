Rails.application.routes.draw do

  mount_devise_token_auth_for 'Owner', at: 'auth'

  resource :open, controller: 'open', only: [] do
    collection do
      get 'clubs'
      post 'checkin'
      post 'remove_checkin'
      get 'list_checkins'
    end
  end

  resources :members, :only => [] do
    collection do
      post :global_search
    end
  end

  resources :clubs do
    member do
      post :assign_tables_straight
      post :assign_tables_every_other
      post :assign_tables_random
    end
    resources :members do
      collection do
        get :checked_in_today
        get :checked_in_on_date
        post :lookup
        post :mark_all_part_time
        post :update_ratings
      end
      resources :checkins
    end
    resources :checkins, :except => [:create]
  end

  get '/ping', to: 'application#ping'
  match '/incoming_call', to: 'application#incoming_call', :via => [:get, :post]
  match '/incoming_text', to: 'application#incoming_text', :via => [:get, :post]
  match '/incoming_sms', to: 'application#incoming_text', :via => [:get, :post]

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
