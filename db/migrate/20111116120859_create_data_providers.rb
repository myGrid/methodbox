class CreateDataProviders < ActiveRecord::Migration
  def self.up
    create_table :data_providers do |t|
       t.string :type
       t.timestamps
     end
  end

  def self.down
    drop_table :data_providers
  end
end
