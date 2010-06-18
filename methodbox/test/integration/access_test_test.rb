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
   end   
      #login_can_get "people/1" unitialised constant sop
   def test_people_edit_self
      login_can_get "people/1/edit" #person 1 is normal_user
   end
   
   def test_people_show_other
      login_can_get "people/2"      
   end
   
   def test_people_edit_other
      admin_can_get "people/2/edit", "Not the current person"  #person 2 is other_person
      #more
   end
   
   def test_scripts_home
      login_can_get "scripts"
   end
   
   def test_scripts_new
      login_can_get "scripts/new"   
   end
      
   def test_scripts_help
      anyone_can_get "scripts/help"
   end
   
   def test_scripts_help2
      anyone_can_get "scripts/help2" 
   end
   
   def test_search_surveys
      anyone_can_get "/search/?search_query=age&search_type=Surveys"
   end
   
   def test_search_people
      login_can_get "/search/?search_query=age&search_type=people"
   end
   
   def test_search_all
      login_can_get "/search/?search_query=age&search_type=all"
   end
      
   def test_surveys
      anyone_can_get "surveys"
      
      #more
      anyone_can_get "surveys/help"
      anyone_can_get "surveys/1-hse1991-1992" 
   end
   
   def test_variable_home
      login_can_get "variables"
      
   end
   
   def test_user_new
      logged_out_and_admin_can_get "users/new"
   end

   def test_variable_help
      #more
      anyone_can_get "variables/help"
   end

   def test_workgroups_home
      login_can_get "work_groups"
   end

   def test_workgroups_new
      login_can_get "work_groups/new"
      #more
      
      #My messages
   end
   
   def admin_can_get(path, adminError = "Admin rights required")      
      login_admin
      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
      assert_select "title",:text=>/MethodBox.*/, :count=>1
      logout
      
      login_normal
      get path
      assert_equal adminError, flash[:error]
      assert_response :redirect      
      assert_nil flash[:notice]
      logout

      get path
      assert_equal "Please log in first",  flash[:error]
      assert_response :redirect      
      assert_redirected_to :controller => "session", :action => "new"
      assert_nil flash[:notice]
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

      get path
      assert_equal "Please log in first",  flash[:error]
      assert_response :redirect      
      assert_redirected_to :controller => "session", :action => "new"
      assert_nil flash[:notice]
      
   end
   

   def logged_out_and_admin_can_get(path, adminError = "Admin rights required")
      login_admin
      get path
      assert_response :success
      assert_nil flash[:error]
      assert_nil flash[:notice]
      assert_select "title",:text=>/MethodBox.*/, :count=>1
      logout

      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
      assert_select "title",:text=>/MethodBox.*/, :count=>1

      login_normal
      get path
      assert_equal adminError,  flash[:error]
      assert_response :redirect      
      assert_nil flash[:notice]
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
   
   #Activate this test to check login if all other tests fail.
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
