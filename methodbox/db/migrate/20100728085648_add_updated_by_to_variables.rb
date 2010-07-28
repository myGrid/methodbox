class AddUpdatedByToVariables < ActiveRecord::Migration
  def self.up
        add_column :variables, :updated_by, :integer
  end

  def self.down
    drop_column :variables, :updated_by
  end
end
