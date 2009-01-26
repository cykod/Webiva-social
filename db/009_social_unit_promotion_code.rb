class SocialUnitPromotionCode < ActiveRecord::Migration
  def self.up
  
    add_column :social_units, :lead_source, :string
  end

  def self.down
    
    remove_column :social_units, :lead_source
  end

end
