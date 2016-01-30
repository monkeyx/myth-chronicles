class ProduceItemAction < BaseAction
	
	PARAMETERS = {
			'produceable_item_id': { required: true, type: 'integer'},
			'quantity': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Settlement]
	SUBTYPE = ['City', 'Guild']

	DESCRIPTION = "<p>Turns raw <a href='/docs/resources'>resources</a> into produced items at your settlement.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		item = Item.where(id: params['produceable_item_id']).first
		unless item 
			add_error('invalid_item')
			return false
		end
		quantity = params['quantity'].to_i
		unless quantity > 0
			add_error('invalid_quantity')
			return false
		end
		unless ((item.armour || item.weapon || item.vehicle || item.siege_equipment) && (self.position.guild? || self.position.city?)) || (item.trade_good && self.position.guild?)
			add_error('invalid_item')
			return false
		end
		if self.position.item_count('Wood') < (item.wood * quantity)
			add_error('insufficient_wood')
			return false
		end
		if self.position.item_count('Hide') < (item.hide * quantity)
			add_error('insufficient_hide')
			return false
		end
		if self.position.item_count('Stone') < (item.stone * quantity)
			add_error('insufficient_stone')
			return false
		end
		if self.position.item_count('Iron') < (item.iron * quantity)
			add_error('insufficient_iron')
			return false
		end
		self.position.add_items!(item, quantity)
		self.position.sub_items!('Wood', (item.wood * quantity))
		self.position.sub_items!('Hide', (item.hide * quantity))
		self.position.sub_items!('Stone', (item.stone * quantity))
		self.position.sub_items!('Iron', (item.iron * quantity))
		add_report({item: item, quantity: quantity})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end
end