class AddFailureToCsvArchive < ActiveRecord::Migration
  def self.up
    add_column :csvarchives, :failure, :boolean
  end

  def self.down
    remove_column :csvarchives, :failure
  end
end
