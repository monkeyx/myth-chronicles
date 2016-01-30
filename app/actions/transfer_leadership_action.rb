class TransferLeadershipAction < BaseAction
	
	PARAMETERS = {
			'member_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Gives away leadership of your alliance to another member.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		unless character && character.lord? && alliance.member?(character)
			add_error('invalid_character')
			return false
		end
		alliance.leader = character
		alliance.save!
		add_report({alliance: alliance, character: character}, 'Success')
		ActionReport.add_report!(character, 'Alliance Leader', I18n.translate('actions.TransferLeadershipAction.Character', {character: character, giver: self.position, alliance: alliance}), self.position)
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end
end