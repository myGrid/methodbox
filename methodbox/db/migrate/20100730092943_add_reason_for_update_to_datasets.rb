class AddReasonForUpdateToDatasets < ActiveRecord::Migration
  def self.up
    add_column :datasets, :reason_for_update, :string
  end

  def self.down
    drop_column :datasets, :reason_for_update
  end
end
