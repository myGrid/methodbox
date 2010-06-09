require 'test_helper'

class SurveysControllerTest < ActionController::TestCase

  def test_search_logged_out
    do_search
    assert_nil flash[:error]
  end

  def test_search_logged_in
    login_as :normal_user
    do_search
    assert_nil flash[:error]
  end

  def test_search_nil_query
    login_as :normal_user
    do_search(:survey_search_query => nil)
    assert_equal "Searching requires a term to be entered in the survey search box.", flash[:error]
  end

  def test_search_empty_query
    login_as :normal_user
    do_search(:survey_search_query => "")
    assert_equal "Searching requires a term to be entered in the survey search box.", flash[:error]
  end

  def test_search_default_query
    login_as :normal_user
    do_search(:survey_search_query => "Enter search terms")
    assert_equal "Searching requires a term to be entered in the survey search box.", flash[:error]
  end

  def test_nil_ids
    login_as :normal_user
    do_search(:entry_ids => nil)
    assert_equal "Searching requires at least one survey selected.", flash[:error]
  end

  def test_empty_ids
    login_as :normal_user
    do_search(:entry_ids => [])
    assert_equal "Searching requires at least one survey selected.", flash[:error]
  end

  def test_bad_ids
    login_as :normal_user
    do_search(:entry_ids => ["-1"])
    assert_equal "Searching failed. Probably due to bad paramteres. Use the survey search box.", flash[:error]
  end

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