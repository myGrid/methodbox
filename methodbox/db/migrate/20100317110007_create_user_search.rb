class CreateUserSearch < ActiveRecord::Migration
  def self.up
    create_table :user_searches do |t|
      t.integer :person_id
      t.string :terms
      t.timestamps
    end
  end

  def self.down
    drop_table :user_searches
  end
end
