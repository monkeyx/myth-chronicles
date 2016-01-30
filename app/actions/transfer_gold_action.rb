class TransferGoldAction < BaseAction
	
	PARAMETERS = {
			'character_id': { required: true, type: 'integer'},
			'amount': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Gives another character some of your gold.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		character = Character.where(id: params['character_id']).first
		unless character
			add_error('invalid_character')
			return false
		end
		amount = params['amount'].to_i
		if amount > self.position.gold 
			add_error('insufficient_gold')
			return false
		end
		self.position.use_gold!(amount)
		character.add_gold!(amount)
		add_report({character: character, amount: amount}, 'Success')
		ActionReport.add_report!(character, 'Gold Transferred', I18n.translate('actions.TransferGoldAction.Character', {character: character, giver: self.position, amount: amount}), self.position)
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end
end