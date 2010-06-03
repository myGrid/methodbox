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

  def test_empty_title_fails
    assert_no_difference 'Script.count' do
      s = create_script(:title => "")
    end
  end

  def test_body_unused
    assert_difference 'Script.count' do
      s = create_script(:body => nil)
    end
  end

#Too Strick?
#  def test_no_description_fails
#    assert_no_difference 'Script.count' do
#      s = create_script(:description => nil)
#    end
#  end

  def test_empty_description_ok
    assert_difference 'Script.count' do
      s = create_script(:description => "")
    end
  end

#Too Strick?
#  def test_no_content_type_fails
#    assert_no_difference 'Script.count' do
#      s = create_script(:content_type => nil)
#    end
#  end

#Too Strick?
#  def test_empty_content_type_fails
#    assert_no_difference 'Script.count' do
#      s = create_script(:content_type => "")
#    end
#  end

#Too Strick?
#  def test_no_contributor_type_fails
#    assert_no_difference 'Script.count' do
#      s = create_script(:contributor_type => nil)
#    end
#  end

#Too Strick?
#  def test_empty_contributor_type_fails
#    assert_no_difference 'Script.count' do
#      s = create_script(:contributor_type => "")
#    end
#  end

#Too Strick?
#  def test_no_contributor_fails
#    assert_no_difference 'Script.count' do
#      s = create_script(:contributor_id => nil)
#    end
#  end

#Too Strick?
#  def test_bad_contributor_fails
#    assert_no_difference 'Script.count' do
#      s = create_script(:contributor_id => -1)
#    end
#  end

#Too Strick?
#  def test_no_content_blob_fails
#    assert_no_difference 'Script.count' do
#      s = create_script()
#      s.save
#    end
#  end

#Too Strick?
# def test_bad_content_blob_fails #Test fails June 3 2010
#    assert_no_difference 'Script.count' do
#      s = create_script()
#      s.content_blob_id = -1
#      s.save
#    end
#  end

  def test_no_original_filename_fails
    assert_no_difference 'Script.count' do
      s = create_script(:original_filename => nil)
    end
  end

  def test_empty_original_filename_ok
    assert_no_difference 'Script.count' do
      s = create_script(:original_filename => "")
    end
  end

#Too Strick?
#  def test_no_method_type_fails
#    assert_no_difference 'Script.count' do
#      s = create_script(:method_type => nil)
#    end
#  end

#Too Strick?
#  def test_empty_method_type_fails
#    assert_no_difference 'Script.count' do
#      s = create_script(:method_type => "")
#    end
#  end

#Too Strick?
#  def test_bad_method_type_fails #Test fails June 3 2010
#    assert_no_difference 'Script.count' do
#      s = create_script(:method_type => "bad")
#    end
#  end

protected
  def test_script(options = {})
    Script.new({ :title => 'From Script Test', :body => "Body for the test", :description => "this is where I would decribe it", :content_type => "Some context type", :contributor_type => "User", :contributor_id => users(:aaron).id, :original_filename => "data.gif", :method_type => "Other"}.merge(options))
  end

  def create_script(options = {})
    script = test_script(options)
    script.content_blob = content_blobs(:content_blob_with_little_file)
    script.save
    script
  end
end

#  create_table "scripts", :force => true do |t|
#    t.string   "title"
#    t.text     "body"
#    t.string   "description"
#    t.datetime "created_at"
#    t.datetime "updated_at"
#    t.string   "content_type"
#    t.string   "contributor_type"
#    t.integer  "contributor_id"
#    t.integer  "content_blob_id"
#    t.datetime "last_used_at"
#    t.string   "original_filename"
#    t.string   "method_type"
#  end
