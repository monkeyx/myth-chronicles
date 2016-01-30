class PickupItemsAction < BaseAction

	PARAMETERS = {
			'item_id': { required: true, type: 'integer'},
			'quantity': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Picks up the specified items from the settlement. The settlement must either belong to your or your army must've been given permission to pick up the items.</p><p><strong>Action Points Cost</strong>: 1</p>"

	ALLIANCE = false
	NO_ALLIANCE = false
	SETTLEMENT_REQUIRED = true

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
		settlement = Settlement.at_loc(self.position.location).not_guilds.first
		unless settlement
			add_error('invalid_location')
			return false
		end
		item = Item.where(id: params['item_id']).first
		quantity = params['quantity'].to_i
		if quantity < 1
			add_error('invalid_quantity')
			return false
		end
		if settlement.item_count(item) < quantity
			quantity = settlement.item_count(item)
		end
		unless settlement.full_permission?(self.position)
			permitted_quantity = settlement.pickup_permission(self.position, item)
			if permitted_quantity < quantity
				quantity = permitted_quantity
			end
		end
		if quantity < 1
			add_error('invalid_item')
			return false
		end
		self.position.add_items!(item, quantity)
		settlement.sub_items!(item, quantity)
		settlement.use_pickup_permission!(self.position, item, quantity)
		add_report({settlement: settlement, item: item, quantity: quantity}, 'Success')
		ActionReport.add_report!(settlement, 'Items Picked Up', I18n.translate('actions.PickupItemsAction.Settlement', {settlement: settlement, army: self.position, item: item, quantity: quantity}), self.position)
		return true
	end

	def action_point_cost 
		FAST_ACTION
	end

end