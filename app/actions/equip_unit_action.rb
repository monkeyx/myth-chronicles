class EquipUnitAction < BaseAction

	PARAMETERS = {
			'owned_item_id': { required: true, type: 'integer'},
			'unit_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Equips the specified unit with the item in your army's inventory provided they can wear it (see <a href='/docs/armies#equipping_units'>here</a>).</p><p><strong>Action Points Cost</strong>: 1</p>"

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
		unless item && item.equippable?
			add_error('invalid_item')
			return false
		end
		unit = Unit.where(id: params['unit_id']).first
		unless unit && unit.army == self.position 
			add_error('invalid_unit')
			return false
		end
		unless unit.can_equip?(item)
			add_error('invalid_equipment')
			return false
		end
		if self.position.item_count(item) < Unit::MINIMUM_ITEM_QUANTITY
			add_error('insufficient_items')
			return false
		end
		if unit.flying? && item.siege_equipment
			add_error('invalid_item')
			return false 
		end
		unit.equip!(item)
		self.position.sub_items!(item, Unit::MINIMUM_ITEM_QUANTITY)
		add_report({unit: unit, item: item})
		return true
	end

	def action_point_cost 
		FAST_ACTION
	end

end