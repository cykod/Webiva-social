class SocialExtensions < ActiveRecord::Migration
  def self.up
    
    add_column :social_unit_types, :missing_image_id,:integer  
    
  end

  def self.down
    remove_column :social_unit_types, :missing_image_id
  end

end
