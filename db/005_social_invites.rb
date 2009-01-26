class SocialInvites < ActiveRecord::Migration
  def self.up
  
    create_table :social_invites, :force => true do |t|
      t.integer :social_unit_id
      t.integer :end_user_id
      t.string :email
      t.timestamps
    end   
    
    add_index :social_invites, :email, :name => 'email_index'

    
  end

  def self.down
    drop_table :social_invites
  end

end
