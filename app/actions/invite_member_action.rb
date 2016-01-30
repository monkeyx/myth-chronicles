class InviteMemberAction < BaseAction
	
	PARAMETERS = {
			'character_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Invites another character to your alliance. You must be leader or given rights by the alliance leader to invite new members.</p><p><strong>Action Points Cost</strong>: 1</p>"

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
		unless self.position.alliance.can_invite?(self.position)
			add_error('no_rights')
			return false
		end
		character = Character.where(id: params['character_id']).first
		unless character 
			add_error('invalid_character')
			return false
		end
		if character.alliance
			add_error('already_allied')
			return false
		end
		self.position.alliance.invite!(character)
		add_report({character: character, alliance: self.position.alliance}, 'Success')
		ActionReport.add_report!(character, 'Invitation to Join Alliance', I18n.translate('actions.InviteMemberAction.Character', {character: character, alliance: self.position.alliance, inviter: self.position}), self.position)
		return true
	end

	def action_point_cost 
		FAST_ACTION
	end

end