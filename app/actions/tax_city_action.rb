class TaxCityAction < BaseAction
	
	PARAMETERS = {
			
		}
	
	POSITION_TYPE = [Settlement]
	SUBTYPE = ['City']

	DESCRIPTION = "<p>Taxes the city population earning you 1 to 6 gold per person. Can only be done once per year.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		unless self.position.population_loyalty > (Settlement::LOYALTY_LOSS_FOR_TAXATION + 1)
			add_error('insufficient_loyalty')
			return false
		end
		if self.position.year_last_taxed == self.position.game.year 
			add_error('already_taxed')
			return false
		end
		gold = self.position.population_size * (rand(6) + 1)
		self.position.owner.add_gold!(gold)
		self.position.population_loyalty -= Settlement::LOYALTY_LOSS_FOR_TAXATION
		self.position.year_last_taxed = self.position.game.year 
		self.position.save!
		add_report({gold: gold, loyalty: self.position.population_loyalty})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end