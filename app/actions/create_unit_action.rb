class CreateUnitAction < BaseAction
	
	PARAMETERS = {
			'race_item_id': { required: true, type: 'integer'},
			'army_id': { required: false, type: 'integer'}
		}
	
	POSITION_TYPE = [Settlement]
	SUBTYPE = :any

	DESCRIPTION = "<p>Creates a new unit using the race item specified. If no army is specified, a new army is created under your command. Only friendly armies can be given units you create.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		item = Item.where(id: params['race_item_id']).first
		army = Army.where(id: params['army_id']).first
		unless item && item.valid_race?
			add_error('invalid_item')
			return false
		end
		if self.position.item_count(item) < Unit::MINIMUM_ITEM_QUANTITY
			add_error('insufficient_items')
			return false
		end
		if item.humanoid? && self.position.owner.gold < Unit::GOLD_COST_TO_CREATE
			add_error('insufficient_gold')
			return false
		end
		if (item.elemental? || item.undead?) && self.position.owner.mana_points < Unit::MANA_COST_TO_CREATE
			add_error('insufficient_mana')
			return false
		end
		if army && !self.position.friendly?(army)
			add_error('invalid_army')
			return false
		end
		unless army 
			army = Position.create_army!(self.position.game, self.position.owner)
		end
		self.position.sub_items!(item, Unit::MINIMUM_ITEM_QUANTITY)
		if item.humanoid?
			self.position.owner.use_gold!(Unit::GOLD_COST_TO_CREATE)
		elsif item.elemental? || item.undead?
			self.position.owner.use_mana_points!(Unit::MANA_COST_TO_CREATE)
		end
		unit = Unit.create_unit!(army, item)
		add_report({unit: unit, army: army})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end
end