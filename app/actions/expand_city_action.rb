class ExpandCityAction < BaseAction
	
	PARAMETERS = {
			'quantity': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Settlement]
	SUBTYPE = ['City']

	DESCRIPTION = "<p>Expands the population of the city using the appropriate humanoids from the inventory.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		item = self.position.recruitment_race_item
		quantity = params['quantity'].to_i
		unless self.position.item_count(item)
			add_error('insufficient_items')
			return false
		end
		self.position.sub_items!(item, quantity)
		self.position.population_size += quantity 
		self.position.population_growth += quantity
		self.position.save!
		Hex.claim_territory!(self.position.game.id, self.position.x, self.position.y, self.position.id, self.position.territory_radius)
		add_report({item: item, quantity: quantity, size: self.position.population_size})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end