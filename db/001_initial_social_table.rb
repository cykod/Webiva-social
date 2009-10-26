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
      t.integer :parent_type_id
      t.integer :child_type_id
      t.boolean :has_location, :default => true
      t.string :category_options
    end
    
    create_table :social_locations, :force => true do |t|
      t.string :name
      t.string :city
      t.string :state
      t.string :zip
      t.boolean :approved, :default => false
      t.timestamps
    end 
    
    add_index :social_locations, :state, :name => 'state_index'
    
    create_table :social_units, :force => true do |t|
      t.string :name
      t.integer :parent_id
      t.integer :social_location_id
      t.integer :social_unit_type_id
      t.boolean :approved, :default => false
      
      t.string :category
      
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      
      t.integer :image_file_id

      t.timestamps
    end   
    
    add_index :social_units, :parent_id, :name => 'parent_index'
    add_index :social_units, [ :social_unit_type_id,:social_location_id,:name ] ,:name => 'type index'
    
    create_table :social_unit_members, :force => true do |t|
      t.integer :social_unit_id
      t.integer :social_unit_type_id # De-normalize for quicker access
      t.integer :social_unit_parent_id # De-normalize for quicker access
      t.integer :end_user_id
      t.string :role, :default => 'member'
      t.string :status
      t.boolean :approved, :default => false

      t.timestamps
    end
    
    add_index :social_unit_members, :social_unit_id, :name => 'social_unit_idex'
    add_index :social_unit_members, :social_unit_parent_id, :name => 'social_parent_idex'
    
    create_table :social_wall_entries, :force => true do |t|
      t.string :target_type, :size => 32
      t.integer :target_id
      
      t.text :message
      t.integer :end_user_id
      t.timestamps
    end
    
    add_index :social_wall_entries, [ :target_type, :target_id ], :name => 'target_index'
    
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
    
  end

  def self.down
    drop_table :social_users
    drop_table :social_unit_types
    drop_table :social_locations
    drop_table :social_units
    drop_table :social_unit_members
    drop_table :social_wall_entries
  end

end
