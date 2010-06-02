require 'test_helper'

class AccessTestTest < ActionController::IntegrationTest

   def test_access
   
      admin_can_get "admin"
      #more
   
      login_can_get "cart" You have a nil object when you didn't expect it
      #more

      login_can_get "csvarchives"
      #more
         
      anyone_can_get "datasets/1-3238" 
      #more
      
      login_can_get "forums"
      #more

      anyone_can_get "help"
      #more
      
      login_can_get "home/index"   
      #more
      
      login_can_get "people"
      #more
      #login_can_get "people/1"  #"unintialized constant Sop"    
      login_can_get "people/2/edit" #user 2 is the one tested as normal
      #more
      
      login_can_get "scripts"
      #more
      anyone_can_get "scripts/help"
      anyone_can_get "scripts/help2" 
      
      anyone_can_get "/search/?search_query=age&search_type=Surveys"
      login_can_get "/search/?search_query=age&search_type=people"
      login_can_get "/search/?search_query=age&search_type=all"
      find_surveys
      anyone_can_get "/search/?search_query=age&search_type=Surveys"
      #how to add variables?

      #anyone_can_get "surveys"
      
      #more
      #anyone_can_get "surveys/help"
      #anyone_can_get "surveys/1-hse1991-1992" 
      
      #login_can_get "work_groups"
      #more
      
      #My messages
   end
   
   def admin_can_get(path)
      get path
      assert_equal "Please log in first",  flash[:error]
      assert_response :redirect      
      assert_redirected_to :controller => "session", :action => "new"
      assert_nil flash[:notice]
      
      login_normal
      get path
      assert_equal "Admin rights required",  flash[:error]
      assert_response :redirect      
      assert_nil flash[:notice]
      logout

      login_admin
      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
      logout
   end

   def anyone_can_get(path)
      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
      
      login_normal    
      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
      logout

      login_admin
      get path
      assert_nil flash[:error]
      assert_response :success
      assert_nil flash[:notice]
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
      logout

      login_admin
      get path
      assert_nil flash[:error]
      assert_response :success
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
