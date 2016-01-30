class SubvertCityAction < BaseAction
	
	PARAMETERS = {
			
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = ['Lord']

	DESCRIPTION = "<p>Attempts to subvert the city, turning it over to your control if successful.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		if settlement.neutral?
			add_error('target_neutral')
			return false
		end
		if self.position.friendly?(settlement)
			add_error('target_friendly')
			return false
		end
		if self.position.check_attribute(:cunning_rating, settlement.population_loyalty)
			previous_owner = settlement.owner
			settlement.owner = self.position
			settlement.save!
			ActionReport.add_report!(previous_owner, 'City Subverted', I18n.translate('actions.SubvertCityAction.Owner', {character: self.position, settlement: settlement}), self.position)
			add_report({settlement: settlement}, 'Success')
		else
			add_report({settlement: settlement}, 'Failure')
		end
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end