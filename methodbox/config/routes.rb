ActionController::Routing::Routes.draw do |map|
  
  map.statistics STATISTICS_ROUTE, :controller=>'statistics',:action=>'index', :requirements => {:protocol => 'http'}
      
  map.resources :cart_items, :requirements => {:protocol => 'http'}

  map.resources :work_groups, :member=>{:request_access=>:post}, :requirements => {:protocol => 'http'}

  map.resources :user_searches, :requirements => {:protocol => 'http'}

  map.resources :publications,:collection=>{:fetch_preview=>:post},:member=>{:disassociate_authors=>:post}, :requirements => {:protocol => 'http'}

  # map.resources :home

  map.resources :help, :requirements => {:protocol => 'http'}

  map.resources :about, :requirements => {:protocol => 'http'}

  map.cart '/cart/', :controller=>'cart',:action=>'show', :requirements => {:protocol => 'http'}

  map.resources :datasets, :member => {:update_metadata=> :get, :update_data=>:get, :load_new_metadata => :post, :load_new_data => :post}, :requirements => {:protocol => 'http'}

  map.resources :variable_links, :requirements => {:protocol => 'http'}

  map.resources :messages, :collection => { :sent => :get, :delete_all_selected => :delete }, :requirements => {:protocol => 'http'}


  map.resources :surveys, :member => {:download => :get}, :collection => {:show_datasets_for_categories => :post, :category_browse => :get, :exhibit => :get, :view_variables => :post, :add_to_pseudo_cart => :get,  :data => :get, :datagrid => :get,:hide_info => :get, :more_info => :get, :search_variables => :post,:sort_variables => :post, :help => :get, :help2 => :get, :search_stuff=>:get, :grid_view => :get,:show_links=>:post}, :requirements => {:protocol => 'http'}

  map.resources :csvarchives, :member => {:download => :get}, :collection =>{:recreate => :post, :help => :get, :help2 => :get,:show_links=>:post, :check_for_complete => :post }, :requirements => {:protocol => 'http'}

  map.resources :variables, :member =>{:update => :post, :search_for_tags => :post, :watch => :get,:add_to_cart=> :post, :open_pdf => :get, :deprecate => :post}, :collection =>{:find_for_multiple_surveys_by_category => :post, :search => :post, :by_category => :get, :add_multiple_to_cart => :post, :help => :get, :grid_view => :get}, :requirements => {:protocol => 'http'}

  map.resources :assets,:member=>{:request_resource=>:post}, :requirements => {:protocol => 'http'}

  map.resources :expertise, :requirements => {:protocol => 'http'}

  map.resources :people, :collection=>{:select=>:get}, :requirements => {:protocol => ROUTES_PROTOCOL} do |person|
    # avatars / pictures 'owned by' person
    person.resources :avatars, :member => { :select => :post }, :collection => { :new => :post }, :requirements => {:protocol => ROUTES_PROTOCOL}
  end

  map.resources :scripts, :member => { :download => :get, :add_comment => :post, :thumbs_up => :post, :thumbs_down => :post }, :collection => {:help => :get, :help2 => :get,:show_links=>:post}, :requirements => {:protocol => 'http'}

  map.resources :projects,
    :collection => { :request_institutions => :get }, :requirements => {:protocol => 'http'} do |project|
    # avatars / pictures 'owned by' project
    project.resources :avatars, :member => { :select => :post }, :collection => { :new => :post }, :requirements => {:protocol => 'http'}
  end

  map.resources :users, :collection=>{:activation_required=>:get,:forgot_password=>[:get,:post],:reset_password=>:get, :unsuspend =>[:get], :resend_actiavtion_code =>[:get]}, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resource :session, :requirements => {:protocol => ROUTES_PROTOCOL}

  # page for admin tasks
  map.admin '/admin/', :controller=>'admin',:action=>'show', :requirements => {:protocol => ROUTES_PROTOCOL}

  # favourite groups
  map.new_favourite_group '/favourite_groups/new', :controller => 'favourite_groups', :action => 'new', :conditions => { :method => :post }, :requirements => {:protocol => 'http'}
  map.create_favourite_group '/favourite_groups/create', :controller => 'favourite_groups', :action => 'create', :conditions => { :method => :post }, :requirements => {:protocol => 'http'}
  map.edit_favourite_group '/favourite_groups/edit', :controller => 'favourite_groups', :action => 'edit', :conditions => { :method => :post }, :requirements => {:protocol => 'http'}
  map.update_favourite_group '/favourite_groups/update', :controller => 'favourite_groups', :action => 'update', :conditions => { :method => :post }, :requirements => {:protocol => 'http'}
  map.delete_favourite_group '/favourite_groups/:id', :controller => 'favourite_groups', :action => 'destroy', :conditions => { :method => :delete }, :requirements => {:protocol => 'http'}

  #  map.tool_list_autocomplete '/tool_list_autocomplete', :controller=>'people', :action=>'auto_complete_for_tools_name'
  map.expertise_list_autocomplete '/expertise_list_autocomplete', :controller=>'people', :action=>'auto_complete_for_expertise_name', :requirements => {:protocol => 'http'}
  #  map.organism_list_autocomplete '/organism_list_autocomplete',:controller=>'projects',:action=>'auto_complete_for_organism_name'

  map.signup  '/signup', :controller => 'users',   :action => 'new', :requirements => {:protocol => ROUTES_PROTOCOL}
  map.login  '/login',  :controller => 'sessions', :action => 'new', :requirements => {:protocol => ROUTES_PROTOCOL}
  map.logout '/logout', :controller => 'sessions', :action => 'destroy', :requirements => {:protocol => ROUTES_PROTOCOL}

  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil, :requirements => {:protocol => 'http'}
  map.forgot_password '/forgot_password',:controller=>'users',:action=>'forgot_password', :requirements => {:protocol => ROUTES_PROTOCOL}

  # used by the "sharing" form to get settings from an existing policy
  map.request_policy_settings '/policies/request_settings', :controller => 'policies', :action => 'send_policy_data', :requirements => {:protocol => 'http'}
  map.root :controller=>'home', :action=>'about', :requirements => {:protocol => 'http'}
  map.index '/index', :controller => 'home', :action=>'index', :requirements => {:protocol => 'http'}

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
