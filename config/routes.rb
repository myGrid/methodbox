MethodBox::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  resources :surveys do
    member do
       get 'show_all_variables'
       get 'add_note'
       get 'download'
     end

     collection do
       get 'retrieve_details'
       get 'collapse_row'
       get 'expand_row'
       post 'add_nesstar_surveys'
       get 'nesstar_datasource'
       post 'new_nesstar_datasource'
       get 'show_datasets_for_categories'
       get 'category_browse'
#TODO why is view variables a post?
       post 'view_variables'
       get 'hide_info'
       get 'more_info'
       get 'search_variables'
       get 'sort_variables'
       get 'show_links'
     end
   end

  resources :variables do
    member do
       post 'update'
       post 'search_for_tags'
       get 'open_pdf'
       post 'deprecate'
#TODO should search for tags and deprecate really be post?
     end

     collection do
       get 'values_array'
#TODO should find for multiple surveys and search be post?
       post 'find_for_multiple_surveys_by_category'
       post 'search'
       get 'by_category'
#TODO is add multiple to cart still used?
       post 'add_multiple_to_cart'
     end
   end

  resources :session do
    member do
      get 'convert_shibboleth_login'
      get 'pre_shibboleth_login'
      get 'shibboleth'
    end
  end

  match  '/signup' => 'users#new'
  match  '/login' => 'sessions#new'
  match '/logout' => 'sessions#destroy'

  root :to => 'home#search'

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
