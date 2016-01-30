class DistributeGoodsAction < BaseAction

	PARAMETERS = {
			'trade_good_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Settlement]
	SUBTYPE = ['City']

	DESCRIPTION = "<p>Distributes the specified trade good to your city's population, improving their loyalty. There must be at least 1 of the specified trade good for every population in the city.</p><p><strong>Action Points Cost</strong>: 2</p>"

	ALLIANCE = false
	NO_ALLIANCE = false
	SETTLEMENT_REQUIRED = false

	def valid_positions
		POSITION_TYPE
	end

	def valid_subtype
		SUBTYPE
	end 

	def parameters
		PARAMETERS
	end

	def transaction!
		item = Item.where(id: params['trade_good_id']).first
		unless item && item.trade_good
			add_error('invalid_item')
			return false
		end
		count = (self.position.population_size / 10)
		if self.position.item_count(item) < count
			add_error('insufficient_items')
			return false
		end
		if self.position.population_loyalty == 100
			add_error('loyalty_maxed')
			return false
		end
		self.position.sub_items!(item, count)
		self.position.population_loyalty = (self.position.population_loyalty + Settlement::LOYALTY_BOOST_FOR_TRADE_GOODS) > 100 ? 100 : (self.position.population_loyalty + Settlement::LOYALTY_BOOST_FOR_TRADE_GOODS)
		self.position.save!
		add_report({item: item, quantity: count, loyalty: self.position.population_loyalty})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end