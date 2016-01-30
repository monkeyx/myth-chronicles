class Buy < Market

	def potential_sellers
		Sell.in_game(self.position.game).for_item(self.item).select do |sell|
			sell.actual_quantity > 0 && sell.actual_price(self.position) <= self.price
		end.sort{|a,b| a.actual_price(self.position) <=> b.actual_price(self.position) }
	end

	def complete_sale!
		transaction do
			potential_sellers.each do |sell|
				qty = sell.actual_quantity
				qty = self.quantity if self.quantity < qty
				price = sell.actual_price(self.position)
				max_buy = (self.position.owner.gold / price).to_i
				qty = max_buy if qty > max_buy
				buyer_cost = qty * price
				seller_income = qty * sell.price

				if qty > 0
					self.position.add_items!(self.item, qty)
					self.position.owner.use_gold!(buyer_cost)
					ActionReport.add_report!(self.position, 'Buy', I18n.translate("trade.buy", {item: self.item, quantity: qty, gold: buyer_cost}), sell.position)

					sell.position.sub_items!(self.item, qty)
					sell.position.owner.add_gold!(seller_income)
					ActionReport.add_report!(sell.position, 'Sell', I18n.translate("trade.sell", {item: self.item, quantity: qty, gold: seller_income}), self.position)

					sell.update_attributes!(quantity: (sell.quantity - qty))
					update_attributes!(quantity: (self.quantity - qty))
				end
				
				return self.quantity < 1
			end
		end
	end
end
