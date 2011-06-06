# THIS IS A DESCTRUCTIVE MIGRATION. PROFILES AND EXPERTISE ARE NOT PRESERVED
class AddProfilesToPeople < ActiveRecord::Migration
  def self.up
         
    add_column :people, :first_name, :string
    add_column :people, :last_name, :string
    add_column :people, :email, :string
    add_column :people, :phone, :string
    add_column :people, :skype_name, :string
    add_column :people, :web_page, :string
    
   
  end

  def self.down    
    
    remove_column :people, :first_name, :last_name, :email, :phone, :skype_name, :web_page
       
  end
end
