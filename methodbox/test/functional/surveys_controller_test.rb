require 'test_helper'

class SurveysControllerTest < ActionController::TestCase

  def test_search_logged_out
    do_search
    assert_nil flash[:error]
    assert_nil flash[:message]
    assert_select "title",:text=>/MethodBox.*/, :count=>1
  end

  def test_search_logged_in
    login_as :normal_user
    do_search
    assert_nil flash[:error]
    assert_nil flash[:message]
    assert_select "title",:text=>/MethodBox.*/, :count=>1
  end

  def test_search_nil_query
    login_as :normal_user
    do_search(:survey_search_query => nil)
    assert_equal "Searching requires a term to be entered in the survey search box.", flash[:error]
    assert_response :redirect
  end

  def test_search_empty_query
    login_as :normal_user
    do_search(:survey_search_query => "")
    assert_equal "Searching requires a term to be entered in the survey search box.", flash[:error]
    assert_response :redirect
  end

  def test_search_default_query
    login_as :normal_user
    do_search(:survey_search_query => "Enter search terms")
    assert_equal "Searching requires a term to be entered in the survey search box.", flash[:error]
    assert_response :redirect
  end

  def test_nil_ids
    login_as :normal_user
    do_search(:entry_ids => nil)
    assert_equal "Searching requires at least one survey selected.", flash[:error]
    assert_response :redirect
  end

  def test_empty_ids
    login_as :normal_user
    do_search(:entry_ids => [])
    assert_equal "Searching requires at least one survey selected.", flash[:error]
    assert_response :redirect
  end

  def test_bad_ids
    login_as :normal_user
    do_search(:entry_ids => ["-1"])
    assert_equal "Incorrect dataset included. Please contact an admin if this reoccurs.", flash[:error]
    assert_response :redirect
  end

  def test_some_bad_ids
    login_as :normal_user
    do_search(:entry_ids => ["3","5","-1"])
    assert_equal "Incorrect dataset included. Please contact an admin if this reoccurs.", flash[:error]
    assert_response :redirect
  end

  #Test Currently fails
  #def test_add_bad_id_to_cart
  #  login_as :normal_user
  #  add_to_cart(:variable_ids => ["-1","2"])
  #  assert_nil flash[:error]
  #end

protected
  def do_search(options = {})
    post :search_variables, {:commit => "Search selected surveys", :survey_search_query => "Age Sex", :entry_ids => ["3","4","5","20","21"], :HSE2000_survey_ids=>[{"9"=>nil}], :per_page =>"10", :page =>"1", :HSE1994_survey_ids=>[{"3"=>nil}]}.merge(options)
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
