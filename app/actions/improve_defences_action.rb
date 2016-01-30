class ImproveDefencesAction < BaseAction
	
	PARAMETERS = {
			
		}
	
	POSITION_TYPE = [Settlement]
	SUBTYPE = ['City', 'Tower', 'Lair']

	DESCRIPTION = "<p>Improves the fortification of this settlement increasing the defence rating at the cost of stone.</p><p><strong>Action Points Cost</strong>: 4</p>"

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
		cost = (1 + self.position.defence_rating)
		cost *= cost 
		cost *= Settlement::IMPROVE_DEFENCES_COST_MULTIPLIER
		if self.position.item_count('Stone') < cost 
			add_error('insufficient_stone')
			return false
		end
		self.position.sub_items!('Stone', cost)
		self.position.defence_rating += 1
		self.position.save!
		add_report({defence_rating: self.position.defence_rating, cost: cost})
		return true
	end

	def action_point_cost 
		SLOW_ACTION
	end

end