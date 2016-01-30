class LeaveArmyAction < BaseAction
	
	PARAMETERS = {
			'army_id': { required: false, type: 'integer'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Your character's unit will leave the army it is with and if specified, join another army. If no army specified, it will form a new army under your command.</p><p><strong>Action Points Cost</strong>: 1</p>"

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
		old_army = self.position.army
		unless params['army_id'].blank?
			army = Army.where(id: params['army_id']).first 
			unless army 
				add_error('invalid_army')
				return false
			end
			unless army.location == self.position.location
				add_error('invalid_location')
				return false
			end
			unless self.position.friendly?(army)
				add_error('not_friendly')
				return false
			end
		else
			army = Position.create_army!(self.position.game, self.position)
		end
		unit = self.position.unit 
		unit.army = army 
		unit.save!
		add_report({old_army: old_army, army: army})
		return true
	end

	def action_point_cost 
		FAST_ACTION
	end

end