class AddForeignKeyIndexes < ActiveRecord::Migration
  def self.up
	add_index :value_domains, :variable_id
	add_index :value_domain_statistics, :value_domain_id
  end

  def self.down
	remove_index :value_domains, :variable_id
	remove_index :value_domain_statistics, :value_domain_id
  end
end
