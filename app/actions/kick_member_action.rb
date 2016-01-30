class KickMemberAction < BaseAction
	
	PARAMETERS = {
			'member_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Removes an existing member from your alliance. You must be the alliance leader or given rights to kick members by the leader.</p><p><strong>Action Points Cost</strong>: 1</p>"

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
		unless self.position.alliance.can_kick?(self.position)
			add_error('no_rights')
			return false
		end
		character = Character.where(id: params['member_id']).first
		unless character && self.position.alliance.member?(character)
			add_error('invalid_character')
			return false
		end
		self.position.alliance.kick!(character)
		add_report({character: character, alliance: self.position.alliance}, 'Success')
		ActionReport.add_report!(character, 'Kicked from Alliance', I18n.translate('actions.KickMemberAction.Character', {character: character, alliance: alliance, kicker: self.position}), self.position)
		alliance.alliance_members.each do |member|
			unless member.member_id == position.id 
				ActionReport.add_report!(member.member, 'Kicked from Alliance', I18n.translate('actions.KickMemberAction.Character', {character: character, alliance: alliance, kicker: self.position}), self.position)
			end
		end
		return true
	end

	def action_point_cost 
		FAST_ACTION
	end

end