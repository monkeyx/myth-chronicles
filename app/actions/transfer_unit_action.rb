class TransferUnitAction < BaseAction

	PARAMETERS = {
			'unit_id': { required: true, type: 'integer'},
			'army_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Transfers the unit specified to another army at the same location.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		army = Army.where(id: params['army_id']).first
		unless army && army.location == self.position.location
			add_error('invalid_army')
			return false
		end
		unit.army = army 
		unit.save!
		add_report({unit: unit, army: army}, 'Success')
		ActionReport.add_report!(army, 'Unit Transferred', I18n.translate('actions.TransferUnitAction.Army', {army: army, giver: self.position, unit: unit}), self.position)
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end