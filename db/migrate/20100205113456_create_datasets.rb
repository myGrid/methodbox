class CreateDatasets < ActiveRecord::Migration
  def self.up
    create_table :datasets do |t|
      t.integer :survey_id
      t.string :name
      t.string :filename
      t.string :description
      t.string :key_variable
      t.timestamps
    end
  end

  def self.down
    drop_table :datasets
  end
end
