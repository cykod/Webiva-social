class SocialRequests < ActiveRecord::Migration
  def self.up
  
    create_table :social_group_requests, :force => true do |t|
      t.integer :social_unit_id
      t.integer :end_user_id
      t.timestamps
    end   
    
    add_column :social_unit_types, :auto_friend, :boolean
    
  end

  def self.down
    drop_table :social_group_requests
    
    remove_column :social_unit_types, :auto_friend
  end

end
