require 'test_helper'

class CartTestTest < ActionController::IntegrationTest

  def test_add_to_cart
    login_normal
    puts CartItem.count
    #normal_user = users(:normal_user)
    assert_cart_size 0
    add_to_cart
    assert_nil flash[:error]
    puts CartItem.count
    #normal_user.reload
    assert_cart_size 2
    add_to_cart(:variable_ids => ["6","8"])
    assert_cart_size 3
    assert_nil flash[:error]
  end

  def test_show_cart
    login_normal
    assert_cart_size 0
    add_to_cart
    assert_nil flash[:error]
    assert_cart_size 2
    get "cart"
    assert_nil flash[:error]
    assert_nil flash[:message]
    assert_select "title",:text=>/MethodBox.*/, :count=>1
    #assert_select :a[href*=variables], :count=> 1
    #<a href="/variables/8008-agepa"
  end

  def test_remove_from_cart
    login_normal
    assert_cart_size 0
    puts CartItem.count
    add_to_cart
    puts CartItem.count
    assert_nil flash[:error]
    assert_cart_size 2
    get "cart"
    assert_select "title",:text=>/MethodBox.*/, :count=>1
    assert_nil flash[:error]
    remove_from_cart
    assert_cart_size 1
    assert_response :success
    assert_nil flash[:message]
    get "cart"
    assert_select "title",:text=>/MethodBox.*/, :count=>1
    #assert_select :a[href*=variables], :count=> 1
    #<a href="/variables/8008-agepa"
  end

  def test_remove_not_in_cart
    login_normal
    assert_cart_size 0
    add_to_cart
    assert_nil flash[:error]
    assert_cart_size 2
    get "cart"
    assert_select "title",:text=>/MethodBox.*/, :count=>1
    assert_nil flash[:error]
    remove_from_cart:variable_ids => ["4"]
    assert_cart_size 2
    assert_response :success
    assert_nil flash[:message]
    get "cart"
    assert_select "title",:text=>/MethodBox.*/, :count=>1
    #assert_select :a[href*=variables], :count=> 1
    #<a href="/variables/8008-agepa"
  end

  def test_remove_all_in_cart
    login_normal
    assert_cart_size 0
    add_to_cart
    assert_nil flash[:error]
    assert_cart_size 2
    get "cart"
    assert_select "title",:text=>/MethodBox.*/, :count=>1
    assert_nil flash[:error]
    remove_from_cart:variable_ids => ["6","7"]
    assert_cart_size 0
    assert_response :success
    assert_nil flash[:message]
    get "cart"
    assert_select "title",:text=>/MethodBox.*/, :count=>1
    #assert_select :a[href*=variables], :count=> 1
    #<a href="/variables/8008-agepa"
  end

  def test_create_csvarchives
    login_normal
    assert_cart_size 0
    add_to_cart
    assert_nil flash[:error]
    assert_cart_size 2
    get "cart"
    assert_select "title",:text=>/MethodBox.*/, :count=>1
    assert_nil flash[:error]
    create_csvarchives
    assert_cart_size 2
    assert_response :found
    assert_nil flash[:message]

    #assert_select :a[href*=variables], :count=> 1
    #<a href="/variables/8008-agepa"
  end

  def test_add_to_cart_not_logged_in
    add_to_cart
    assert_equal "Please log in first", flash[:error]
  end

  #Test Currently fails
  #def test_add_bad_id_to_cart
  #  login_as :normal_user
  #  add_to_cart(:variable_ids => ["-1","2"])
  #  assert_nil flash[:error]
  #end

  protected

  def add_to_cart(options = {})
    post "surveys/add_to_cart", {:submit => "add", :variable_ids => ["6","7"] }.merge(options)
  end

  def remove_from_cart(options = {})
    post "cart/remove_from_cart", {:submit => "remove_variables", :variable_ids => ["7"] }.merge(options)
  end

  def create_csvarchives(options = {})
    post "csvarchives/create", :archive=>{:title=>"test"}.merge(options)
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

  def assert_cart_size(size)
      normal_user = users(:normal_user)
      normal_user.reload
      assert_equal size, normal_user.cart_items.size
  end
end


#Parameters: {
#  "commit"=>"Search selected surveys",
#  "action"=>"search_variables",
#  "authenticity_token"=>"27laEzK9rL5o24JHwT+koMZGX81V1QEB99FJVEPVIco=",
#  "survey_search_query"=>"some",
#  "entry_ids"=>[
#    {"3"=>nil},
#    {"4"=>nil},
#    {"5"=>nil},
#    {"20"=>nil},
#    {"21"=>nil}],
#  "HSE2000_survey_ids"=>[
#    {"9"=>nil}],
#  "controller"=>"surveys",
#  "per_page"=>"10",
#  "page"=>"1",
#  "HSE1994_survey_ids"=>[
#    {"3"=>nil}]}

#Parameters: {
#"year_of_survey"=>"survey_year",
#"tag_button"=>"tag",
#"variable_identifier"=>"variable_identifier",
#"variable_list"=[{"7499"=>nil}, {"8441"=>nil}, {"6984"=>nil}, {"7289"=>nil}, {"7290"=>nil}, {"7581"=>nil}, {"7590"=>nil}, {"7648"=>nil}, {"8007"=>nil}, {"8008"=>nil}, {"8011"=>nil}, {"8012"=>nil}, {"7287"=>nil}, {"7288"=>nil}, {"7705"=>nil}, {"7706"=>nil}, {"7707"=>nil}, {"7708"=>nil}, {"7709"=>nil}, {"7730"=>nil}, {"7748"=>nil}, {"7760"=>nil}, {"8359"=>nil}, {"7580"=>nil}, {"8358"=>nil}, {"7059"=>nil}, {"7995"=>nil}, {"8349"=>nil}, {"7039"=>nil}, {"7040"=>nil}, {"7041"=>nil}, {"7042"=>nil}, {"7077"=>nil}, {"8407"=>nil}, {"8193"=>nil}, {"6968"=>nil}, {"7283"=>nil}, {"7917"=>nil}, {"8352"=>nil}, {"6967"=>nil}, {"8350"=>nil}, {"8351"=>nil}],
#"add_results"=>"no",
#"submit"=>"add",
#"survey_list"=>[{"1"=>nil}, {"2"=>nil}],
#"sorted_variables"=>[{"7499"=>nil}, {"8441"=>nil}, {"6984"=>nil}, {"7289"=>nil}, {"7290"=>nil}, {"7581"=>nil}, {"7590"=>nil}, {"7648"=>nil}, {"8007"=>nil}, {"8008"=>nil}, {"8011"=>nil}, {"8012"=>nil}, {"7287"=>nil}, {"7288"=>nil}, {"7705"=>nil}, {"7706"=>nil}, {"7707"=>nil}, {"7708"=>nil}, {"7709"=>nil}, {"7730"=>nil}, {"7748"=>nil},{"7760"=>nil}, {"8359"=>nil}, {"7580"=>nil}, {"8358"=>nil}, {"7059"=>nil}, {"7995"=>nil}, {"8349"=>nil}, {"7039"=>nil}, {"7040"=>nil}, {"7041"=>nil}, {"7042"=>nil}, {"7077"=>nil}, {"8407"=>nil}, {"8193"=>nil}, {"6968"=>nil}, {"7283"=>nil}, {"7917"=>nil}, {"8352"=>nil}, {"6967"=>nil}, {"8350"=>nil}, {"8351"=>nil}],
#"variable_ids"=>[{"6984"=>nil}, {"7289"=>nil}],
#"action"=>"add_to_cart",
#"authenticity_token"=>"WS2tpyO4tqGDRLWySrIqil6W3kVZWZeg5+JqGv/4Kgg=",
#"survey_search_query"=>"age",
#"entry_ids"=>[{"1"=>nil}, {"2"=>nil}],
#"watch_variable"=>"watch_variable",
#"_submit"=>"Add selected variables to cart",
#"controller"=>"surveys",
#"variable_name"=>"variable_name"}

#Parameters: {
#"submit"=>"remove_variables",
#"sorted_variables"=>[{"8008"=>nil}, {"8663"=>nil}, {"9715"=>nil}],
#"variable_ids"=>[{"8008"=>nil}],
#"action"=>"remove_from_cart", #"authenticity_token"=>"C3x+8FypkbpodZO5q9j7l2W+v2eu4u7HQ9yiTMcg03Y=",
#"_submit"=>"Removebles from cart",
#"controller"=>"cart"}

#Parameters: {
	#"archive"=>{
	#	"title"=>"test",
	#	"description"=>""},
	#"attributions"=>"[]",
	#"action"=>"create",
	#"authenticity_token"=>"+2+Jj/xyOlPUDRVBeTBMdMNl0+g/sCbS9ASgNLq52WQ=",
	#"controller"=>"csvarchives",
	#"sharing"=>{
	#	"include_custom_sharing_0"=>"0",
	#	"access_type_0"=>"0",
	#	"permissions"=>{
	#		"values"=>"",
	#		"contributor_types"=>""},
	#	"access_type_3"=>"1",
	#	"sharing_scope"=>"3"}}