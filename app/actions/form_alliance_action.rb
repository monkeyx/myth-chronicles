class FormAllianceAction < BaseAction 
	
	PARAMETERS = {
			'name': { required: true, type: 'string'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = ['Lord']

	DESCRIPTION = "<p>Forms a new alliance under your leadership.</p><p><strong>Action Points Cost</strong>: 2</p>"

	ALLIANCE = false
	NO_ALLIANCE = true
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
		if self.position.alliance 
			add_error('already_allied')
			return false
		end
		alliance = Alliance.create!(leader: self.position, name: params['name'], game_time: self.position.game.game_time)
		self.position.alliance = alliance 
		self.position.save!
		add_report({alliance: alliance})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end
end