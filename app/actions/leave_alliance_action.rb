class LeaveAllianceAction < BaseAction
	
	PARAMETERS = {
			
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Leave your current alliance.</p><p><strong>Action Points Cost</strong>: 1</p>"

	ALLIANCE = true
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
		unless self.position.alliance 
			add_error('not_in_alliance')
			return false
		end
		alliance = self.position.alliance
		self.position.alliance.leave!(self.position)
		add_report({alliance: alliance}, 'Success')
		alliance.alliance_members.each do |member|
			unless member.member_id == position.id 
				ActionReport.add_report!(member.member, 'Left Alliance', I18n.translate('actions.LeaveAllianceAction.Left', {character: self.position, alliance: alliance}), self.position)
			end
		end
		return true
	end

	def action_point_cost 
		FAST_ACTION
	end

end