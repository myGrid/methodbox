class AddArchivedReasonToVariable < ActiveRecord::Migration
  def self.up
    add_column :variables, :archived_reason, :string
  end

  def self.down
    drop_column :variables, :archived_reason
  end
end
