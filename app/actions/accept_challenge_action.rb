class AcceptChallengeAction < BaseAction

	PARAMETERS = {
			'challenge_id': { required: true, type: 'integer'}
		}

	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Accepts a challenge to personal combat from another character.</p>
	<p><strong>Action Points Cost</strong>: 2</p>"

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
		challenge = CharacterChallenge.were(id: params['challenge_id']).first
		unless challenge && challenge.character == self.position 
			add_error('invalid_challenge')
			return false
		end
		unless challenge.challenger
			add_error('invalid_challenge')
			return false
		end
		unless challenge.location == self.position.location 
			challenge.reject!
			add_error('invalid_location')
			return false 
		end
		unless challenge.challenger.location == challenge.location 
			challenge.cancel!
			add_error('invalid_challenge')
			return false
		end
		if challenge.expired?
			challenge.reject!
			add_error('challenge_expired')
			return false
		end
		unless challenge.accept!
			self.errors = challenge.errors
			return false
		else
			add_report({challenger: challenge.challenger}, 'Success')
			ActionReport.add_report!(challenge.challenger, 'Challenged Accepted', I18n.translate('actions.AcceptChallengeAction.Challenger', {character: self.position}), self.position)
			return true
		end
	end

	def action_point_cost
		NORMAL_ACTION
	end
end