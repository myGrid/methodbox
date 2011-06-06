class AddUpdateReasonToVariables < ActiveRecord::Migration
  def self.up
    add_column :variables, :update_reason, :string
  end

  def self.down
    drop_column :variables, :update_reason
  end
end
