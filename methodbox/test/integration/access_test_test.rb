require 'test_helper'

class AccessTestTest < ActionController::IntegrationTest

   def test_admin  
      admin_can_get "admin"
      #more
   end
   
   def test_cart
      #login_can_get "cart" #You have a nil object when you didn't expect it
      #more
   end
   
   def test_csvarchives
      login_can_get "csvarchives"
      #more
   end
   
   def test_datasets
      anyone_can_get "datasets/1-3238" 
      #more
   end
   
   def test_forums
      login_can_get "forums"
      #more
   end
   
   def test_help
      anyone_can_get "help"
      #more
   end
   
   def test_home
      login_can_get "home/index"   
      #more
   end
   
   def test_people
      login_can_get "people"
      #more
      #login_can_get "people/1" unitialised constant sop
      login_can_get "people/1/edit" #person 1 is normal_user
      login_can_get "people/2"      
      admin_can_get "people/2/edit", "Not the current person"  #person 2 is other_person
      #more
   end
   
   def test_scripts
      login_can_get "scripts"
      login_can_get "scripts/new"   
   
      #more
      anyone_can_get "scripts/help"
      anyone_can_get "scripts/help2" 
   end
   
   def test_search      
      anyone_can_get "/search/?search_query=age&search_type=Surveys"
      login_can_get "/search/?search_query=age&search_type=people"
      login_can_get "/search/?search_query=age&search_type=all"
      anyone_can_get "/search/?search_query=age&search_type=Surveys"
      #how to add variables?
   end
   
   def test_surveys
      anyone_can_get "surveys"
      
      #more
      anyone_can_get "surveys/help"
      anyone_can_get "surveys/1-hse1991-1992" 
   end
   
   def test_variable
      login_can_get "variables"
      
      #more
      anyone_can_get "variables/help"
   end

   def xest_workgroups      
      login_can_get "work_groups"
      #more
      
      #My messages
   end
   
   def admin_can_get(path, adminError = "Admin rights required")      
      get path
      assert_equal "Please log in first",  flash[:error]
      assert_response :redirect      
      assert_redirected_to :controller => "session", :action => "new"
      assert_nil flash[:notice]
      
      login_normal
      get path
      assert_equal adminError,  flash[:error]
      assert_response :redirect      
      assert_nil flash[:notice]
      logout

      login_admin
      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
      assert_select "title",:text=>/MethodBox.*/, :count=>1
      logout
   end

   def anyone_can_get(path)
      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
      assert_select "title",:text=>/MethodBox.*/, :count=>1
      
      login_normal    
      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
      assert_select "title",:text=>/MethodBox.*/, :count=>1
      logout

      login_admin
      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
      assert_select "title",:text=>/MethodBox.*/, :count=>1
      logout
   end

   def login_can_get(path)
      get path
      assert_equal "Please log in first",  flash[:error]
      assert_response :redirect      
      assert_redirected_to :controller => "session", :action => "new"
      assert_nil flash[:notice]
      
      login_normal
      get path
      assert_response :success
      assert_nil flash[:error]
      assert_nil flash[:notice]
      assert_select "title",:text=>/MethodBox.*/, :count=>1
      logout

      login_admin
      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
      assert_select "title",:text=>/MethodBox.*/, :count=>1
      logout
   end

   def login_admin
      post "sessions/create", :login => 'quentin@example.com', :password => 'test'
   end
   
   def login_normal
      post "sessions/create", :login => 'aaron@example.com', :password => 'test'
   end
   
   def logout
      post "sessions/destroy"
   end
   
   def est_login_and_logout
      login_normal
      assert_nil flash[:error]
      assert_response :redirect
      assert_nil flash[:notice]
      
      logout
      assert_nil flash[:error]
      assert_response :redirect
      assert_nil flash[:notice]

      login_admin
      assert_nil flash[:error]
      assert_response :redirect
      assert_nil flash[:notice]
      
      logout
      assert_nil flash[:error]
      assert_response :redirect
      assert_nil flash[:notice]
   end
end
