class RecruitHumanoidsAction < BaseAction
	
	PARAMETERS = {
			
	}
	
	POSITION_TYPE = [Character]
	SUBTYPE = ['Hero']

	DESCRIPTION = "<p>Recruits humanoids found in this hex to your army.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		hex = self.position.hex
		unless Terrain::CITY_TERRAIN_RECRUITMENT.keys.include?(hex.terrain)
			add_error('invalid_location')
			return false
		end
		race = Terrain::CITY_TERRAIN_RECRUITMENT[hex.terrain]
		quantity = 0
		if Races::RARE_RACES.include?(race)
			quantity = rand(1)
		elsif Races::FRISKY_RACES.include?(race)
			quantity = rand(100) + 1
		else
			quantity = rand(10) + 1
		end
		self.position.army.add_items!(race, quantity)
		add_report({race: race.pluralize(quantity), quantity: quantity})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end