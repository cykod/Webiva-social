class SocialBlockTable < ActiveRecord::Migration
  def self.up
  
    create_table :social_blocks, :force => true do |t|
      t.integer :end_user_id
      t.integer :blocked_user_id
      t.timestamps
    end   
    
    add_index :social_blocks, [:blocked_user_id],:name =>'blocked'
    add_index :social_blocks, [:end_user_id],:name =>'my_blocked'

    
  end

  def self.down
    drop_table :social_blocks
  end

end
