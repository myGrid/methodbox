ActionController::Routing::Routes.draw do |map|

  #  map.view_variables  '/surveys/view_variables', :controller => 'surveys',   :action => 'view_variables'
  #
  #  map.search_variables '/surveys/search_variables', :controller => 'surveys', :action => 'search_variables'
  #
  #  map.order_variables '/surveys/order_variables', :controller => 'surveys',   :action => 'order_variables'

  #  map.resources :created_datas
  #
  #  map.resources :assay_types
  #
  #  map.resources :organisms
  #
  #  map.resources :technology_types
  #
  #  map.resources :measured_items
  #
  #  map.resources :investigations

  #  map.resources :studies

  # messages
   # page for cart
   
  map.resources :work_groups
  
  # map.resources :home

  map.resources :help
  
  map.resources :about

  map.cart '/cart/', :controller=>'cart',:action=>'show'

  map.resources :datasets

  map.resources :variable_links

  map.resources :messages, :collection => { :sent => :get, :delete_all_selected => :delete }


  map.resources :surveys, :member => {:download => :get}, :collection => {:view_variables => :post, :add_to_pseudo_cart => :get,  :data => :get, :datagrid => :get,:hide_info => :get, :more_info => :get, :search_variables => :post,:sort_variables => :post, :help => :get, :search_stuff=>:get, :grid_view => :get}
#  do |survey|
#
#  end

  map.resources :csvarchives, :member => {:download => :get}, :collection =>{:recreate => :post, :help => :get, :help2 => :get}
  
  #  map.resources :assays

  map.resources :variables, :member =>{:update => :post, :search_for_tags => :post, :watch => :get,:add_to_cart=> :post, :open_pdf => :get}, :collection =>{:search => :post, :by_category => :get, :add_multiple_to_cart => :post, :help => :get, :grid_view => :get}

#  map.resources :methods, :collection => {:help => :get}

  map.resources :assets,:member=>{:request_resource=>:post}

  #  map.resources :data_files, :member => {:download => :get}  do |data_file|
  #    data_file.resources :studied_factors
  #  end

  map.resources :expertise

  #  map.resources :institutions,
  #    :collection => { :request_all => :get } do |institution|
  #    # avatars / pictures 'owned by' institution
  #    institution.resources :avatars, :member => { :select => :post }, :collection => { :new => :post }
  #  end
  #
  #  map.resources :groups
  #
  #  map.resources :models, :member => { :download => :get, :execute=>:post }

  map.resources :people, :collection=>{:select=>:get} do |person|
    # avatars / pictures 'owned by' person
    person.resources :avatars, :member => { :select => :post }, :collection => { :new => :post }
  end

  map.resources :scripts, :member => { :download => :get }, :collection => {:help => :get, :help2 => :get}

  map.resources :projects,
    :collection => { :request_institutions => :get } do |project|
    # avatars / pictures 'owned by' project
    project.resources :avatars, :member => { :select => :post }, :collection => { :new => :post }
  end

  #  map.resources :sops, :member => { :download => :get } do |sop|
  #    sop.resources :experimental_conditions
  #  end

  map.resources :users, :collection=>{:activation_required=>:get,:forgot_password=>[:get,:post],:reset_password=>:get}

  map.resource :session      
  
  # browsing by countries
  #  map.country '/countries/:country_name', :controller => 'countries', :action => 'show'

  # page for admin tasks
  map.admin '/admin/', :controller=>'admin',:action=>'show'

  # favourite groups
  map.new_favourite_group '/favourite_groups/new', :controller => 'favourite_groups', :action => 'new', :conditions => { :method => :post }
  map.create_favourite_group '/favourite_groups/create', :controller => 'favourite_groups', :action => 'create', :conditions => { :method => :post }
  map.edit_favourite_group '/favourite_groups/edit', :controller => 'favourite_groups', :action => 'edit', :conditions => { :method => :post }
  map.update_favourite_group '/favourite_groups/update', :controller => 'favourite_groups', :action => 'update', :conditions => { :method => :post }
  map.delete_favourite_group '/favourite_groups/:id', :controller => 'favourite_groups', :action => 'destroy', :conditions => { :method => :delete }

  #  map.new_investigation_redbox 'studies/new_investigation_redbox',:controller=>"studies",:action=>'new_investigation_redbox',:conditions=> {:method=>:post}
  #  map.create_investigation 'experiments/create_investigation',:controller=>"studies",:action=>'create_investigation',:conditions=> {:method=>:post}
  #
  #
  #  # review members of workgroup (also of a project / institution) popup
  #  map.review_work_group '/work_groups/review/:type/:id/:access_type', :controller => 'work_groups', :action => 'review_popup', :conditions => { :method => :post }
  
  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  
  #

  #  map.tool_list_autocomplete '/tool_list_autocomplete', :controller=>'people', :action=>'auto_complete_for_tools_name'
  map.expertise_list_autocomplete '/expertise_list_autocomplete', :controller=>'people', :action=>'auto_complete_for_expertise_name'
  #  map.organism_list_autocomplete '/organism_list_autocomplete',:controller=>'projects',:action=>'auto_complete_for_organism_name'
  
  map.signup  '/signup', :controller => 'users',   :action => 'new' 
  map.login  '/login',  :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'  
  
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil
  map.forgot_password '/forgot_password',:controller=>'users',:action=>'forgot_password'
  
  # used by the "sharing" form to get settings from an existing policy 
  map.request_policy_settings '/policies/request_settings', :controller => 'policies', :action => 'send_policy_data'
  map.root :controller=>'home', :action=>'about'
  map.index '/index', :controller => 'home', :action=>'index'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
