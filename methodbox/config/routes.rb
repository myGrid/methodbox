ActionController::Routing::Routes.draw do |map|
  
  map.statistics STATISTICS_ROUTE, :controller=>'statistics',:action=>'index', :requirements => {:protocol => ROUTES_PROTOCOL}
      
  map.resources :cart_items, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :work_groups, :member=>{:request_access=>:post}, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :user_searches, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :publications,:collection=>{:fetch_preview=>:post},:member=>{:disassociate_authors=>:post}, :requirements => {:protocol => ROUTES_PROTOCOL}

  # map.resources :home

  map.resources :help, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :about, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.cart '/cart/', :controller=>'cart',:action=>'show', :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :datasets, :member => {:update_metadata=> :get, :update_data=>:get, :load_new_metadata => :post, :load_new_data => :post}, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :variable_links, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :messages, :collection => { :autocomplete_message_to => :post, :sent => :get, :delete_all_selected => :delete }, :requirements => {:protocol => ROUTES_PROTOCOL}


  map.resources :surveys, :member => { :show_all_variables => :post, :add_note => :post, :download => :get}, :collection => {:collapse_row => :post, :expand_row => :post, :add_nesstar_surveys => :post, :nesstar_datasource => :get, :new_nesstar_datasource => :post, :show_datasets_for_categories => :post, :category_browse => :get, :facets => :get, :view_variables => :post, :add_to_pseudo_cart => :get,  :data => :get, :datagrid => :get,:hide_info => :get, :more_info => :get, :search_variables => :post,:sort_variables => :post, :help => :get, :help2 => :get, :search_stuff=>:get, :grid_view => :get,:show_links=>:post}, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :csvarchives, :member => {:add_note => :post, :download_stats_script => :get, :download => :get, :thumbs_up => :post, :thumbs_down => :post }, :collection =>{:recreate => :post, :help => :get, :help2 => :get,:show_links=>:post, :check_for_complete => :post }, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :variables, :member =>{:update => :post, :search_for_tags => :post, :watch => :get,:add_to_cart=> :post, :open_pdf => :get, :deprecate => :post}, :collection =>{:find_for_multiple_surveys_by_category => :post, :search => :post, :by_category => :get, :add_multiple_to_cart => :post, :help => :get, :grid_view => :get}, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :assets,:member=>{:request_resource=>:post}, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :expertise, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :people, :collection=>{:select=>:get}, :requirements => {:protocol => ROUTES_PROTOCOL} do |person|
    # avatars / pictures 'owned by' person
    person.resources :avatars, :member => { :select => :post }, :collection => { :new => :post }, :requirements => {:protocol => ROUTES_PROTOCOL}
  end

  map.resources :scripts, :member => { :add_note => :post, :download => :get, :add_comment => :post, :thumbs_up => :post, :thumbs_down => :post }, :collection => {:help => :get, :help2 => :get,:show_links=>:post}, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resources :projects,
    :collection => { :request_institutions => :get }, :requirements => {:protocol => ROUTES_PROTOCOL} do |project|
    # avatars / pictures 'owned by' project
    project.resources :avatars, :member => { :select => :post }, :collection => { :new => :post }, :requirements => {:protocol => ROUTES_PROTOCOL}
  end

  map.resources :users, :member => { :shib_convert_after => :get }, :collection=>{ :new_shib => :get, :create_shib => :post, :activation_required=>:get,:forgot_password=>[:get,:post],:reset_password=>:get, :unsuspend =>[:get], :resend_activation_code =>[:get]}, :requirements => {:protocol => ROUTES_PROTOCOL}

  map.resource :session, :collection => { :shibboleth => :get}, :requirements => {:protocol => ROUTES_PROTOCOL}

  # page for admin tasks
  map.admin '/admin/', :controller=>'admin',:action=>'show', :requirements => {:protocol => ROUTES_PROTOCOL}

  # favourite groups
  map.new_favourite_group '/favourite_groups/new', :controller => 'favourite_groups', :action => 'new', :conditions => { :method => :post }, :requirements => {:protocol => ROUTES_PROTOCOL}
  map.create_favourite_group '/favourite_groups/create', :controller => 'favourite_groups', :action => 'create', :conditions => { :method => :post }, :requirements => {:protocol => ROUTES_PROTOCOL}
  map.edit_favourite_group '/favourite_groups/edit', :controller => 'favourite_groups', :action => 'edit', :conditions => { :method => :post }, :requirements => {:protocol => ROUTES_PROTOCOL}
  map.update_favourite_group '/favourite_groups/update', :controller => 'favourite_groups', :action => 'update', :conditions => { :method => :post }, :requirements => {:protocol => ROUTES_PROTOCOL}
  map.delete_favourite_group '/favourite_groups/:id', :controller => 'favourite_groups', :action => 'destroy', :conditions => { :method => :delete }, :requirements => {:protocol => ROUTES_PROTOCOL}

  #  map.tool_list_autocomplete '/tool_list_autocomplete', :controller=>'people', :action=>'auto_complete_for_tools_name'
  map.expertise_list_autocomplete '/expertise_list_autocomplete', :controller=>'people', :action=>'auto_complete_for_expertise_name', :requirements => {:protocol => ROUTES_PROTOCOL}
  #  map.organism_list_autocomplete '/organism_list_autocomplete',:controller=>'projects',:action=>'auto_complete_for_organism_name'

  map.signup  '/signup', :controller => 'users',   :action => 'new', :requirements => {:protocol => ROUTES_PROTOCOL}
  map.login  '/login',  :controller => 'sessions', :action => 'new', :requirements => {:protocol => ROUTES_PROTOCOL}
  map.logout '/logout', :controller => 'sessions', :action => 'destroy', :requirements => {:protocol => ROUTES_PROTOCOL}

  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil, :requirements => {:protocol => ROUTES_PROTOCOL}
  map.forgot_password '/forgot_password',:controller=>'users',:action=>'forgot_password', :requirements => {:protocol => ROUTES_PROTOCOL}

  # used by the "sharing" form to get settings from an existing policy
  map.request_policy_settings '/policies/request_settings', :controller => 'policies', :action => 'send_policy_data', :requirements => {:protocol => ROUTES_PROTOCOL}
  map.root :controller=>'home', :action=>'about', :requirements => {:protocol => ROUTES_PROTOCOL}
  map.index '/index', :controller => 'home', :action=>'index', :requirements => {:protocol => ROUTES_PROTOCOL}

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
