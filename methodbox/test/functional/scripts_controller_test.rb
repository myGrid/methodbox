require 'test_helper'

class ScriptsControllerTest < ActionController::TestCase

  #No test for flash[:error] as popped up rather than set

  def test_empty_file
    login_as :aaron
    assert_no_difference 'Script.count' do
	    post :create, :script => {:title => 'test script', :data => ''}
	 end
  end

end
