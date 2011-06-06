class CreateValueDomainStatistics < ActiveRecord::Migration
  def self.up
    create_table :value_domain_statistics, :force => true do |t|
      t.string   :value_domain_id
      t.string   :frequency
      t.timestamps
    end
  end

  def self.down
    drop_table :value_domain_statistics
  end
end
