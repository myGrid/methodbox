class CreateStataDoFile < ActiveRecord::Migration
  def self.up
    create_table :stata_do_files do |t|
      t.column :data, :binary, :limit => 1073741824
      t.column :name, :string
      t.column :csvarchive_id, :integer
    end
  end

  def self.down
    drop_table :stata_do_files
  end
end
