require 'test_helper'

class AvatarsControllerTest < ActionController::TestCase
  
  def setup
    login_as(:normal_user)
  end

  test "show new" do
    get :new, :person_id=>people(:normal_person).id
    assert_response :success
  end
end
