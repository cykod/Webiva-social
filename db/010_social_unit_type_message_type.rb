
class SocialUnitTypeMessageType < ActiveRecord::Migration
  def self.up
  
    add_column :social_unit_types, :child_message, :boolean, :default => false
  end

  def self.down
    
    remove_column :social_unit_types, :child_message
  end

end
