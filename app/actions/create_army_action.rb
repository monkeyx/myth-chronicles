class CreateArmyAction < BaseAction
	
	PARAMETERS = {
			'name': { required: true, type: 'string'},
			'unit_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Splits off one of this army's units to create a new army at the same location under your command.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		unless unit && unit.army == self.position 
			add_error('invalid_unit')
			return false
		end
		new_army = Position.create_army!(self.position.game, self.position.owner, params['name'])
		unit.army = new_army
		unit.save!
		add_report({new_army: new_army, unit: unit})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end
end