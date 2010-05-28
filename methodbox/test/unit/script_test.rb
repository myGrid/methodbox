require 'test_helper'

class ScriptTest < ActiveSupport::TestCase

  def test_create_new_ok
    assert_difference 'Script.count' do
      s = create_script()
    end
  end

  def test_no_title_fails
    assert_no_difference 'Script.count' do
      s = create_script(:title => nil)
    end
  end

  def test_no_filename_fails
    assert_no_difference 'Script.count' do
      s = create_script(:original_filename => nil)
    end
  end

protected
  def create_script(options = {})
    record = Script.new({ :title => 'From Script Test', :body => "Body for the test", :description => "this is where I would decribe it", :content_type => "Some context type", :original_filename => "data.gif"}.merge(options))
    record.save
    record
  end

end

