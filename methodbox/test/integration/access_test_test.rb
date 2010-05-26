require 'test_helper'

class AccessTestTest < ActionController::IntegrationTest

   def test_access
      login_can_get "home/index"   

      #login_can_get "cart" You have a nil object when you didn't expect it
      #more
      
      #login_can_get "datasets/1-3238" #need to add data
      #more
      
      login_can_get "people"
      #login_can_get "people/1"  #"unintialized constant Sop"    
      #login_can_get "people/2/edit" #user 2 is the one tested as normal
      
      login_can_get "scripts"
      #login_can_get "scripts/index" '#redirect
      anyone_can_get "scripts/help"
      anyone_can_get "scripts/help2" 

      login_can_get "surveys"
      #login_can_get "surveys/1-hse1991-1992" #need to add data
      
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
   
   def test_login_and_logout
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
