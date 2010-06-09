require 'test_helper'

class SurveysControllerTest < ActionController::TestCase

  def test_temp_logged_out
    do_search
  end
  
  def test_temp_logged_in
    login_as :normal_user
    do_search
  end

  protected
  def do_search(options = {})
    post :search_variables, {:commit => "Search selected surveys", :survey_search_query => "Age Sex", :entry_ids => ["3","4","5","20","21"], :HSE2000_survey_ids=>[{"9"=>nil}], :per_page =>"10", :page =>"1", :HSE1994_survey_ids=>[{"3"=>nil}]}.merge(options) 
    assert_nil flash[:error]
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