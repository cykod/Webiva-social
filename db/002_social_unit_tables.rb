class SocialUnitTables < ActiveRecord::Migration
  def self.up
  
    create_table :social_pictures, :force => true do |t|
      t.string :image_type
      t.integer :image_file_id
      t.string :caption
      t.boolean :approved
      t.integer :end_user_id
    end
    
  end

  def self.down
    drop_table :social_pictures
  end

end
