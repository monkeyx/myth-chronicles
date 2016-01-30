class TransferPositionAction < BaseAction
	
	PARAMETERS = {
			'owned_position_id': { required: true, type: 'integer'},
			'character_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Transfers the given settlement or army to another character.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		transfer_position = Position.where(id: params['owned_position_id']).first
		if transfer_position.character || transfer_position.owner.id != self.position.id
			add_error('invalid_position')
			return false
		end
		if transfer_position.settlement && !transfer_position.settlement.allowed_owner_type?(character.character_type)
			add_error('invalid_character')
			return false
		end
		transfer_position.owner = character
		transfer_position.save!
		add_report({position: transfer_position, character: character}, 'Success')
		ActionReport.add_report!(character, transfer_position.position_type + ' Transferred', I18n.translate('actions.TransferPositionAction.Character', {character: character, giver: self.position, position: transfer_position}), self.position)
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end