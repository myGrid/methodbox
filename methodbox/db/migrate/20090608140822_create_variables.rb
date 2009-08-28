class CreateVariables < ActiveRecord::Migration
  def self.up
    create_table :variables do |t|
      t.string :name
      t.string :value

      t.timestamps

      t.integer :survey_id
    end
  end

  def self.down
    drop_table :variables
  end
end
