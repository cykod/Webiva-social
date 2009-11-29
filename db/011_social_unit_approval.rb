
class SocialUnitApproval < ActiveRecord::Migration
  def self.up
    add_column :social_units, :approved_until, :datetime
    add_column :social_units, :created_by_id, :integer
    add_column :social_units, :website, :string
    add_column :social_unit_types, :access_token_id, :integer
  end

  def self.down
    remove_column :social_units, :approved_until
    remove_column :social_units, :created_by_id
    remove_column :social_units, :website
    remove_column :social_unit_types, :access_token_id
  end

end
