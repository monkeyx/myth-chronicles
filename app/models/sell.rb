class Sell < Market

	def actual_quantity
		qty = self.position.item_count(item)
		qty < self.quantity ? qty : self.quantity
	end

	def transaction_cost(other_position)
		cost = (self.position.distance(other_position) / 10).round
		cost = 1 if cost < 1
		cost
	end

	def actual_price(other_position)
		self.price + transaction_cost(other_position)
	end
end
