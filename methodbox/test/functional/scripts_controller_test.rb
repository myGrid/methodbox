require 'test_helper'

class ScriptsControllerTest < ActionController::TestCase

  #No test for flash[:error] as popped up rather than set

  def test_create_no_script
    login_as :aaron
    assert_no_difference 'Script.count' do
      post :create, :title => 'test script', :data => ''
    end
  end

  def test_empty_file
    login_as :aaron
    assert_no_difference 'Script.count' do
      post :create, :script => {:title => 'test script', :data => ''}
    end
  end

  def test_create_ok
    login_as :aaron
    assert_difference 'Script.count' do
      create_script()
    end
    assert_nil flash[:error]
    assert_nil flash[:notice]
    assert_response :redirect
   end

  #FIXME There must be a better way of doing this but Tempfile didn't have the size method required.
  class MethodBoxTempFile

    def initialize(data, content_type, original_filename)
      @data = data
      @content_type = content_type
      @original_filename = original_filename
    end

    def content_type
      @content_type
    end

    def original_filename
      @original_filename
    end

    def read
      @data
    end

    def blank?
      !@data
    end

    def size
      @data.size
    end

  end

protected
  def create_script(options = {})
    temp_file = MethodBoxTempFile.new('The Data','text','fake.txt')
    post :create, :script => {:title => 'From Script Test', :body => "Body for the test", :description => "this is where I would decribe it", :contributor_type => "User", :data => temp_file}, :method_type => "Other"
  end


#"script"=> {
#  "title"=>"Test 1",
#  "description"=>"",
#  "data"=>#<File:C:/Users/CHRIST~1/AppData/Local/Temp/RackMultipart.5052.0>},
#    .content_type
#    .original_filename
#    .read
#.."attributions"=>"[]",
#"action"=>"create",
#"authenticity_token"=>"mjw08PeArdkVXSu8TTgL1vmvw1eHDP3DWQYbI4DdOVM=",
#"controller"=>"scripts",
#"method_type"=>"Other",
#"sharing"=>{
#.."include_custom_sharing_0"=>"0",
#  "access_type_0"=>"0",
#  "permissions"=>{
#    "values"=>"",
#    "contributor_types"=>""},
#  "access_type_3"=>"1",
#  "sharing_scope"=>"3"}}

end
