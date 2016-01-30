class InspireCityAction < BaseAction
	
	PARAMETERS = {
			
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Inspires the city's population, increasing their loyalty and using up one renown.</p><p><strong>Action Points Cost</strong>: 2</p>"

	ALLIANCE = false
	NO_ALLIANCE = false
	SETTLEMENT_REQUIRED = true

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
		settlement = Settlement.at_loc(self.position.location).city.first
		unless settlement
			add_error('invalid_location')
			return false
		end
		unless self.position.friendly?(settlement)
			add_error('not_friendly_location')
			return false
		end
		if self.position.renown < 1
			add_error('insufficient_renown')
			return false
		end
		if settlement.population_loyalty == 100
			add_error('loyalty_maxed')
			return false
		end
		settlement.population_loyalty = (settlement.population_loyalty + Character::INSPIRATION_LOYALTY_BOOST) > 100 ? 100 : (settlement.population_loyalty + Character::INSPIRATION_LOYALTY_BOOST)
		settlement.save!
		self.position.use_renown!(1)
		add_report({settlement: settlement, loyalty: settlement.population_loyalty}, 'Success')
		ActionReport.add_report!(settlement, 'Inspired', I18n.translate('actions.AcceptChallengeAction.Settlement', {settlement: settlement, loyalty: settlement.population_loyalty, character: self.position}), self.position)
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end