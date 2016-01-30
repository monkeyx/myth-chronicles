class ChallengeCharacterAction < BaseAction
	
	PARAMETERS = {
			'character_id': { required: true, type: 'integer'}
		}

	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Challenges the character to personal combat. Only works if the character is not-friendly and at the current location.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		other = Character.where(id: params['character_id']).first
		unless other
			add_error('invalid_character')
			return false
		end
		unless self.position.location == other.location 
			add_error('invalid_location')
			return false
		end
		if self.position.friendly?(other)
			add_error('target_friendly')
			return false
		end
		self.position.challenge!(other)
		add_report({other: other}, 'Success')
		ActionReport.add_report!(other, 'Challenged', I18n.translate('actions.ChallengeCharacterAction.Other', {character: self.position, other: other}), self.position)
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end
end