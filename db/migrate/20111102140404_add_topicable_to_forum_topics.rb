class AddTopicableToForumTopics < ActiveRecord::Migration
  def self.up
      add_column :topics, :topicable_id, :integer
      add_column :topics, :topicable_type, :string
  end

  def self.down
      remove_column :topics, :topicable_id
      remove_column :topics, :topicable_type
  end
end
