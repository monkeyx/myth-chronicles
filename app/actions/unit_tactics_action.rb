class UnitTacticsAction < BaseAction
	
	PARAMETERS = {
			'unit_id': { required: true, type: 'integer'},
			'tactic': { required: true, type: 'string'}
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Changes the tactics used by the unit in combat.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		unless unit && unit.army.id == self.position.id 
			add_error('invalid_unit')
			return false
		end
		tactic = params['tactic']
		unless unit.can_adopt_tactic?(tactic)
			add_error('invalid_tactic')
			return false
		end
		unit.tactic = tactic
		unit.save!
		add_report({unit: unit, tactic: tactic})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end