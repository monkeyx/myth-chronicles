class AcceptMembershipAction < BaseAction
	
	PARAMETERS = {
			'alliance_id': { required: true, type: 'integer'}
		}

	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Accepts an invitation to join the specified alliance.</p><p><strong>Action Points Cost</strong>: 1</p>"

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
		alliance = Alliance.where(id: params['alliance_id']).first
		unless alliance
			add_error('invalid_alliance')
			return false
		end
		unless (invite = alliance.invited?(self.position))
			add_error('not_invited')
			return false
		end
		unless invite.accept!
			self.errors = invite.errors
			return false
		else
			add_report({alliance: alliance}, 'Success')
			alliance.alliance_members.each do |member|
				unless member.member_id == self.position.id
					ActionReport.add_report!(member.member, 'Joined Alliance', I18n.translate('actions.AcceptMembershipAction.Joined', {character: self.position, alliance: alliance}), self.position)
				end
			end
			return true
		end
	end

	def action_point_cost 
		FAST_ACTION
	end
end