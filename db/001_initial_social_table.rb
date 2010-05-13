class InitialSocialTable < ActiveRecord::Migration
  def self.up
  
    create_table :social_users, :force => true do |t|
      t.integer :end_user_id
      t.string :role
      t.integer :social_location_id
    end
    
    add_index :social_users, :end_user_id, :name => 'user_index'

    create_table :social_unit_types, :force => true do |t|
      t.string :name
      t.boolean :has_parents,:default => false
      t.boolean :has_children, :default => false
      t.integer :content_model_id
      t.integer :content_model_field_id
      t.string  :content_model_field_name
      t.integer :parent_type_id
      t.integer :child_type_id
      t.boolean :has_location, :default => true
      t.boolean :validate_join, :default => true
      t.string :category_options
      t.integer :missing_image_id
      t.boolean :social_unit_types, :auto_friend 
      t.boolean :child_message, :default => false

      t.boolean :member_create_events, :default => false
      t.string :sub_groups, :limit => 32

      t.integer :access_token_id
      
    end
    
    create_table :social_locations, :force => true do |t|
      t.string :name
      t.string :city
      t.string :state
      t.string :zip
      t.boolean :approved, :default => false
      t.timestamps
      t.string :url
    end 
    
    add_index :social_locations, :url
    
    create_table :social_units, :force => true do |t|
      t.string :name
      t.string :url, :limit => 128
      t.integer :parent_id
      t.integer :social_location_id
      t.integer :social_unit_type_id
      t.boolean :approved, :default => false
      
      t.string :category
      
      t.string :address
      t.string :city
      t.string :state, :limit => 16
      t.string :zip, :limit => 32
      t.string :website
      
      t.string :lead_source

      t.integer :image_file_id

      t.datetime :approved_until
      t.integer :created_by_id

      t.timestamps
    end   
    

    add_index :social_units, :url
    add_index :social_units, :parent_id, :name => 'parent_index'
    add_index :social_units, [ :social_unit_type_id,:social_location_id,:name ] ,:name => 'type index'
    
    create_table :social_unit_members, :force => true do |t|
      t.integer :social_unit_id
      t.integer :social_unit_type_id # De-normalize for quicker access
      t.integer :social_unit_parent_id # De-normalize for quicker access
      t.integer :end_user_id
      t.string :role, :default => 'member', :limit => 16
      t.string :status, :limit => 16
      t.boolean :approved, :default => false

      t.timestamps
    end
    
    add_index :social_unit_members, :social_unit_id, :name => 'social_unit_idex'
    add_index :social_unit_members, :social_unit_parent_id, :name => 'social_parent_idex'
    
    create_table :social_friends, :force => true do |t|
      t.integer :end_user_id
      t.integer :friend_user_id
      t.boolean :approved, :default => false
      t.boolean :automatic, :default => false
      t.integer :social_unit_id  
      t.timestamps
    end
    
    add_index :social_friends, [ :end_user_id] ,:name => 'user_index'
    add_index :social_friends, [ :friend_user_id ], :name => 'friend_index'    
    
      
    create_table :social_invites, :force => true do |t|
      t.integer :social_unit_id
      t.integer :end_user_id
      t.string :email
      t.boolean :admin_invite, :default => false
      t.timestamps
    end   
    
    add_index :social_invites, :email, :name => 'email_index'


    create_table :social_blocks, :force => true do |t|
      t.integer :end_user_id
      t.integer :blocked_user_id
      t.timestamps
    end   
    
    add_index :social_blocks, [:blocked_user_id],:name =>'blocked'
    add_index :social_blocks, [:end_user_id],:name =>'my_blocked'

  end

  def self.down
    drop_table :social_users
    drop_table :social_unit_types
    drop_table :social_locations
    drop_table :social_units
    drop_table :social_unit_members
    drop_table :social_invites
    drop_table :social_blocks
  end

end
