class ChangeValdomIdToIntInStatsTable < ActiveRecord::Migration
  def self.up
    change_column :value_domain_statistics, :value_domain_id, :integer
  end

  def self.down
    change_column :value_domain_statistics, :value_domain_id, :string
  end
end
