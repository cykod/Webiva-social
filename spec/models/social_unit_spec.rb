# Copyright (C) 2009 Pascal Rettig.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"


describe SocialUnit do

  reset_domain_tables  :social_units, :social_unit_types


  it "should be able to create a unit" do
    grp_type = SocialUnitType.create(:name => 'Group')
    grp = SocialUnit.create(:name => 'tester', :social_unit_type_id => grp_type)
    grp.should be_valid

  end

  
end
