class PositionItem < ActiveRecord::Base

	belongs_to :position 
	belongs_to :item
	validates :quantity, numericality: {only_integer: true, greater_than_or_equal_to: 0}

	scope :for_position, ->(position) { where(position_id: position.id )}
	scope :for_item, ->(item) { where(item_id: item.id )}
	scope :has_some, -> { where("quantity > 0")}
	scope :has_quantity, ->(quantity) { where(["quantity >= ?", quantity])}

	scope :order_by_name, -> { joins(:item).order("items.name ASC")}

	def to_s
		"#{item} x #{quantity}"
	end

	def as_json(options={})
		{
			item: item,
			quantity: quantity
		}
	end
end
