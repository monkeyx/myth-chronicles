class FormSettlementAction < BaseAction
	
	PARAMETERS = {
			'name': { required: true, type: 'string'}
		}

	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Forms a new settlement at the current location. The <a href='/docs/settlements'>type and costs</a> depends on your character.</p><p><strong>Action Points Cost</strong>: 4</p>"

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
		settlement_type = self.position.owner.settlement_type
		name = params['name']
		if self.position.item_count('Wood') < Settlement::FORM_WOOD_COST[settlement_type]
			add_error('insufficient_wood')
			return false
		end

		if self.position.item_count('Stone') < Settlement::FORM_STONE_COST[settlement_type]
			add_error('insufficient_stone')
			return false
		end

		if self.position.owner.gold < Settlement::FORM_GOLD_COST[settlement_type]
			add_error('insufficient_gold')
			return false
		end

		if self.position.owner.mana_points < Settlement::FORM_MANA_COST[settlement_type]
			add_error('insufficient_mana')
			return false
		end
		
		settlement = nil
		if settlement_type == 'Guild'
			city = Settlement.at_loc(self.position.location).city.first
			unless city 
				add_error('invalid_location')
				return false
			end
			settlement = Settlement.create_guild!(city, name, self.position.owner)
		else
			hex = self.position.hex
			if hex.territory
				add_error('already_territory')
				return false
			end
			unless hex.valid_for_settlement?(settlement_type)
				add_error('invalid_location')
				return false
			end
			case settlement_type
			when 'City'
				item = Item.of_race(hex.terrain_city_recruitment).first
				humanoid_count = self.position.item_count(item)
				if humanoid_count < Settlement::FORM_CITY_MINIMUM_HUMANOIDS
					add_error('insufficient_humanoids')
					return false
				end
				settlement = Settlement.create_city!(self.position.game, self.position.location, name, hex.terrain_city_recruitment, humanoid_count, self.position.owner)
				self.position.sub_items!(item, humanoid_count)
			when 'Lair'
				settlement = Settlement.create_lair!(self.position.game, self.position.location, name, self.position.owner)
			when 'Tower'
				settlement = Settlement.create_tower!(self.position.game, self.position.location, name, self.position.owner)
			end
		end
		self.position.sub_items!('Wood', Settlement::FORM_WOOD_COST[settlement_type]) if Settlement::FORM_WOOD_COST[settlement_type] > 0
		self.position.sub_items!('Stone', Settlement::FORM_STONE_COST[settlement_type]) if Settlement::FORM_STONE_COST[settlement_type] > 0
		self.position.owner.use_gold!(Settlement::FORM_GOLD_COST[settlement_type]) if Settlement::FORM_GOLD_COST[settlement_type] > 0
		self.position.owner.use_mana_points!(Settlement::FORM_MANA_COST[settlement_type]) if Settlement::FORM_MANA_COST[settlement_type] > 0
		add_report({settlement: settlement, settlement_type: settlement_type})
		Rumour.report_settlement_formed!(settlement)
		return true
	end

	def action_point_cost 
		SLOW_ACTION
	end
end