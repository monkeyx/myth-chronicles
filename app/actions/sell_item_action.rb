class SellItemAction < BaseAction
	
	PARAMETERS = {
			'owned_item_id': { required: true, type: 'integer'},
			'quantity': { required: true, type: 'integer'},
			'price': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Settlement]
	SUBTYPE = :any

	DESCRIPTION = "<p>Offers to sell items at the specified price and quantity.</p><p><strong>Action Points Cost</strong>: 1</p>"

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
		item = Item.where(id: params['owned_item_id']).first
		unless item 
			add_error('invalid_item')
			return false
		end
		quantity = params['quantity'].to_i
		unless quantity > 0
			add_error('invalid_quantity')
			return false
		end
		price = params['price'].to_i
		unless price > 0
			add_error('invalid_price')
			return false
		end
		sell = Sell.where(position: self.position.position, item: item).first
		unless sell
			Sell.create!(position: self.position.position, item: item, quantity: quantity, price: price)
		else
			sell.update_attributes!(quantity: quantity, price: price)
		end
		add_report({item: item, quantity: quantity, price: price})
		return true
	end

	def action_point_cost 
		FAST_ACTION
	end

end