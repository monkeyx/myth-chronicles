class SettlementPermission < ActiveRecord::Base

	belongs_to :settlement
	belongs_to :position
	belongs_to :alliance
	# full
	belongs_to :item
	validates :quantity, numericality: {only_integer: true, greater_than_or_equal_to: 0}

	scope :for_settlement, ->(settlement) { where({settlement_id: settlement.id })}
	scope :for_position, ->(position) { where({position_id: position.id })}
	scope :for_alliance, ->(alliance) { where({alliance_id: alliance.id })}
	scope :full, -> { where({full: true})}
	scope :for_item, ->(item) { where({item_id: item.id })}
	scope :has_some, -> { where(["settlement_permissions.full = ? OR settlement_permissions.quantity > 0", true])}

	def as_json(options={})
		{
			settlement: {
				id: settlement.id,
				name: settlement.name
			},
			position: {
				id: position.id,
				name: position.name
			},
			alliance: alliance,
			full: full,
			item: item,
			quantity: quantity
		}
	end
end
