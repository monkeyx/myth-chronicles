class PermitMemberAction < BaseAction
	
	PARAMETERS = {
			'member_id': { required: true, type: 'integer'},
			'news': { required: false, type: 'boolean'},
			'invite': { required: false, type: 'boolean'},
			'kick': { required: false, type: 'boolean'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = ['Lord']

	DESCRIPTION = "<p>Gives or revokes an alliance member's rights to invite others, kick out members or publish news. Only the alliance leader can do this.</p><p><strong>Action Points Cost</strong>: 1</p>"

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
		alliance = self.position.alliance
		unless alliance
			add_error('not_in_alliance')
			return false
		end
		unless alliance.leader?(self.position)
			add_error('not_leader')
			return false
		end
		character = Character.where(id: params['member_id']).first
		unless character && alliance.member?(character)
			add_error('invalid_character')
			return false
		end
		if is_true?('news')
			alliance.give_publish_news_rights!(character)
			add_report({character: character}, 'GiveNews')
		elsif is_false?('news')
			alliance.revoke_publish_news_rights!(character)
			add_report({character: character}, 'RevokeNews')
		end
		if is_true?('invite')
			alliance.give_invite_rights!(character)
			add_report({character: character}, 'GiveInvite')
		elsif is_false?('invite')
			alliance.revoke_invite_rights!(character)
			add_report({character: character}, 'RevokeInvite')
		end
		if is_true?('kick')
			alliance.give_kick_rights!(character)
			add_report({character: character}, 'GiveKick')
		elsif is_false?('kick')
			alliance.revoke_kick_rights!(character)
			add_report({character: character}, 'RevokeKick')
		end
		ActionReport.add_report!(character, 'Alliance Rights Changed', I18n.translate('actions.PermitMemberAction.Character', {character: character, alliance: alliance}), self.position)
		return true
	end

	def action_point_cost 
		FAST_ACTION
	end

end