class Market < ActiveRecord::Base

	belongs_to :position
	belongs_to :item
	validates :quantity, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :price, numericality: {only_integer: true, greater_than_or_equal_to: 0}

	scope :for_position, ->(position) { where({position_id: position.id })}
	scope :in_game, ->(game) { joins(:position).where(["positions.game_id = ?", game.id])}
	scope :for_item, ->(item) { where({item_id: item.id })}
	scope :buying, -> { where(market_type: 'Buy')}
	scope :selling, -> { where(market_type: 'Sell')}

	after_save :check_quantity

	self.inheritance_column = :market_type

	def buying?
		market_type == 'Buy'
	end

	def selling?
		market_type == 'Sell'
	end

	def check_quantity
		destroy if self.quantity == 0
	end

	def as_json(options={})
		{
			item: item.name,
			buying: buying? ? quantity : '-',
			selling: selling? ? quantity : '-',
			price: price
		}
	end
end
