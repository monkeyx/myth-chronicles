class TransferItemAction < BaseAction
	
	PARAMETERS = {
			'position_id': { required: true, type: 'integer'},
			'owned_item_id': { required: true, type: 'integer'},
			'quantity': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Army, Character, Settlement]
	SUBTYPE = :any

	DESCRIPTION = "<p>Transfers the specified items to another position at the same location.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		target = Position.where(id: params['position_id']).first
		unless target
			add_error('invalid_target')
			return false
		end
		unless target.location == self.position.location
			add_error('invalid_location')
			return false
		end
		item = Item.where(id: params['owned_item_id']).first
		unless item 
			add_error('invalid_item')
			return false
		end
		quantity = params['quantity'].to_i
		if self.position.item_count(item) < quantity
			add_error('insufficient_items')
			return false
		end
		if target.character && !item.magical
			add_error('invalid_item')
			return false
		end
		self.position.sub_items!(item, quantity)
		target.add_items!(item, quantity)
		add_report({target: target, item: item, quantity: quantity}, 'Success')
		ActionReport.add_report!(target, 'Item Transferred', I18n.translate('actions.TransferItemAction.Target', {target: target, giver: self.position, item: item, quantity: quantity}), self.position)
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end
end