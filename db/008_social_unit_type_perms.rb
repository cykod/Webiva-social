class SocialUnitTypePerms < ActiveRecord::Migration
  def self.up
  
    add_column :social_unit_types, :member_create_events, :boolean, :default => false
    add_column :social_unit_types, :sub_groups, :string
  end

  def self.down
    
    remove_column :social_unit_types,:member_create_events
    remove_column :sub_groups
  end

end
