class EquipMagicAction < BaseAction

	PARAMETERS = {
			'owned_item_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Equips a magical item in your inventory into the appropriate slot. Your character must be able to use the item specifed (see <a href='/docs/characters'>here</a>).</p><p><strong>Action Points Cost</strong>: 1</p>"

	ALLIANCE = false
	NO_ALLIANCE = false
	SETTLEMENT_REQUIRED = false

	def valid_positions
		[Character]
	end

	def parameters
		PARAMETERS
	end

	def transaction!
		item = Item.where(id: params['owned_item_id']).first
		unless item && item.magical
			add_error('invalid_item')
			return false
		end
		unless self.position.item_count(item) > 0
			add_error('insufficient_items')
			return false
		end
		unless self.position.can_wear?(item)
			add_error('invalid_equipment')
			return false
		end
		self.position.sub_items!(item, 1)
		self.position.equip!(item)
		add_report({item: item, stat: item.stat_modified.to_s.gsub("_rating",""), modifier: item.stat_modifier})
		return true
	end

	def action_point_cost 
		FAST_ACTION
	end

end