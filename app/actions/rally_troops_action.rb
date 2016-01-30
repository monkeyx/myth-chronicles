class RallyTroopsAction < BaseAction

	PARAMETERS = {
			'unit_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Rallies a unit, restoring it to full health at the cost of one renown.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		unit = Unit.where(id: params['unit_id']).first
		unless unit 
			add_error('invalid_unit')
			return false
		end
		unless self.position.friendly?(unit.army)
			add_error('not_friendly')
			return false
		end
		unless self.position.location == unit.army.location 
			add_error('invalid_location')
			return false
		end
		unless self.position.renown > 0
			add_error('insufficient_renown')
			return false
		end
		if unit.health == 100
			add_error('unit_healthy')
			return false
		end
		unit.health = 100
		unit.save!
		self.position.use_renown!(1)
		add_report({unit: unit, army: unit.army})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end