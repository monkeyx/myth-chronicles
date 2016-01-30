class ChangeNameAction < BaseAction

	PARAMETERS = {
			'name': { required: true, type: 'string' }
		}
	
	POSITION_TYPE = [Army, Character, Settlement]
	SUBTYPE = :any

	DESCRIPTION = "<p>Changes the name of the position.</p><p><strong>Action Points Cost</strong>: 0</p>"

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
		old_name = self.position.name
		self.position.name = params['name']
		unless self.position.save
			set_errors self.position.errors
			return false
		else
			add_report({old_name: old_name, new_name: params['name']})
			return true
		end
	end

	def action_point_cost
		FREE_ACTION
	end

end