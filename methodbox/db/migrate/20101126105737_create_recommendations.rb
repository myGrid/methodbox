class CreateRecommendations < ActiveRecord::Migration
  def self.up
    create_table :recommendations do |t|
      t.column :user_id, :integer
      t.column :recommendable_id, :integer
      t.column :recommendable_type, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :recommendations
  end
end
