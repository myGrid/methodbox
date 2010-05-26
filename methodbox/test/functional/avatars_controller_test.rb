require 'test_helper'

class AvatarsControllerTest < ActionController::TestCase
  
  def setup
    login_as(:quentin)
  end

  test "show new" do
    get :new, :person_id=>people(:one).id
    assert_response :success
  end
end
