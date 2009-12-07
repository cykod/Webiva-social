
class Social::UnitActivation < Shop::ProductFeature

  def self.shop_product_feature_handler_info
    { 
    :name => 'Activate a social unit',
    :callbacks => [ :purchase, :stock ],
    :options_partial => "/social/handler/unit_activation"
    }
  end

  def purchase(user,order_item,session)
    if @options.social_unit_type_id
      @susr = SocialUser.user(user)
      @group = @susr.social_units(@options.social_unit_type_id)[0]

      if @group
        @group.update_attributes(:approved => true,
                                 :approved_until => @options.activate_until )
      end
    end
  end

  def stock(opts,user)
    @susr = SocialUser.user(user)
    @group = @susr.social_units(@options.social_unit_type_id)[0]


    # No group - can't register
    if !@group
      0
    else
      if !@options.activate_until
        @group.approved? ? 0 : 1
      else
        if !@group.approved  || !@group.approved_until || @group.approved_until < @options.activate_until
          1
        else
          0
        end
      end
    end
  end

  def self.options(val)
    UnitActivationOptions.new(val)
  end
  
  class UnitActivationOptions < HashModel
    attributes :social_unit_type_id => nil, :activate_until => nil

    validates_date :activate_until

    validates_presence_of :social_unit_type_id 

  end

  def self.description(opts)
    opts = self.options(opts)
    sprintf("Activate Social Unit (%s)", opts.activate_until ? opts.activate_until.strftime(DEFAULT_DATE_FORMAT.t) : 'Unlimited' )
  end
  

end
