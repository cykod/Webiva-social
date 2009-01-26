class SocialGroupOptions < ActiveRecord::Migration
  def self.up
  
    add_column :social_unit_types, :wall_post, :text
    add_column :social_unit_types, :wall_post_user_id, :integer
    
    add_column :social_invites, :admin_invite, :boolean, :default => false
  end

  def self.down
    
    remove_column :social_invites, :admin_invite
    remove_column :social_unit_types, :wall_post
    remove_column :social_unit_types,:wall_post_user_id
  end

end
