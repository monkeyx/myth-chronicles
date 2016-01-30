class CastSpellAction < BaseAction

	PARAMETERS = {
			'spell': { required: true, type: 'string'},
			'target': { required: true, type: 'string'},
			'mana_spend': { required: false, type: 'integer'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Casts the <a href='/docs/spells'>magical spell</a> specified provided your character has the mana points to do so.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		unless self.position.can_cast?(params['spell'])
			add_error('invalid_spell')
			return false
		end
		success = case params['spell']
		when 'Bless'
			cast_bless!(params['target'], params['mana_spend'].to_i)
		when 'Heal'
			cast_heal!(params['target'], params['mana_spend'].to_i)
		when 'Ritual'
			cast_ritual!(params['target'].to_i, params['mana_spend'].to_i)
		when 'Scry'
			cast_scry!(params['target'])
		when 'Teleport'
			cast_teleport!(params['target'])
		end
		return success
	end

	def cast_bless!(unit_id, mana_spend)
		unless self.position.craft_rating > 0
			add_error('insufficient_craft_rating')
			return false
		end
		unless self.position.mana_points >= mana_spend
			add_error('insufficient_mana')
			return false
		end
		unit = Unit.where(id: unit_id).first
		unless unit
			add_error('invalid_unit')
			return false
		end
		unless unit.army.friendly?(self.position)
			add_error('not_friendly')
			return false
		end
		unless unit.location == self.position.location 
			add_error('invalid_location')
			return false
		end
		bless_rating = (Character::BLESS_PER_MANA_CRAFT_FACTORS * mana_spend * self.position.craft_rating).to_i
		unless bless_rating > 0
			add_error('insufficient_mana')
			return false
		end
		unit.bless_rating = bless_rating
		unit.save!
		self.position.use_mana_points!(mana_spend)
		add_report({mana_spend: mana_spend, bless_rating: bless_rating, unit: unit}, 'Bless')
		return true
	end

	def cast_heal!(unit_id, mana_spend)
		unless self.position.craft_rating > 0
			add_error('insufficient_craft_rating')
			return false
		end
		unless self.position.mana_points >= mana_spend
			add_error('insufficient_mana')
			return false
		end
		unit = Unit.where(id: unit_id).first
		unless unit
			add_error('invalid_unit')
			return false
		end
		unless self.position.friendly?(unit.army)
			add_error('not_friendly')
			return false
		end
		unless unit.health < 100
			add_error('unit_healthy')
			return false
		end
		unless unit.location == self.position.location 
			add_error('invalid_location')
			return false
		end
		heal_points = (Character::HEAL_PER_MANA_CRAFT_FACTORS * mana_spend * self.position.craft_rating).round
		unless heal_points > 0
			add_error('insufficient_mana')
			return false
		end
		heal_points = (100 - unit.health) if unit.health + heal_points > 100
		mana_spend = ((1 / (Character::HEAL_PER_MANA_CRAFT_FACTORS * self.position.craft_rating)) * heal_points).round
		unit.health += heal_points
		unit.save!
		self.position.use_mana_points!(mana_spend)
		add_report({mana_spend: mana_spend, heal_points: heal_points, unit: unit}, 'Heal')
		return true
	end

	def cast_ritual!(item_id, mana_spend)
		unless self.position.craft_rating > 0
			add_error('insufficient_craft_rating')
			return false
		end
		unless self.position.mana_points >= mana_spend
			add_error('insufficient_mana')
			return false
		end
		item = Item.where(id: item_id).first
		unless item
			add_error('invalid_item')
			return false
		end
		settlement = Settlement.at_loc(self.position.location).of_type(self.position.settlement_type).first
		unless settlement 
			add_error('invalid_location')
			return false
		end
		unless self.position.friendly?(settlement)
			add_error('not_friendly_location')
			return false
		end
		quantity = (mana_spend * self.position.craft_rating) / item.complexity
		if quantity < 1
			add_error('insufficient_mana')
			return false
		end
		settlement.add_items!(item, quantity)
		self.position.use_mana_points!(mana_spend)
		if rand(100) + 1 <= mana_spend
			self.position.add_experience_points!(1)
		end
		add_report({item: item, quantity: quantity, mana_spend: mana_spend, settlement: settlement},'RitualMundane')
		return true
	end

	def cast_scry!(location_id)
		unless self.position.craft_rating > 0
			add_error('insufficient_craft_rating')
			return false
		end
		target = Hex.in_game(self.position.game).at_id(location_id).first
		unless target
			add_error('invalid_location')
			return false
		end
		mana_spend = ((self.position.location.distance(target) * Character::SCRY_MANA_COST_MULTIPLIER) / self.position.craft_rating).round
		unless self.position.mana_points >= mana_spend
			add_error('insufficient_mana')
			return false
		end
		self.position.army.scout!(target, self.position, self.position.craft_rating)
		self.position.use_mana_points!(mana_spend)
		add_report({target: target, mana_spend: mana_spend}, 'Scry')
		return true
	end

	def cast_teleport!(location_id)
		unless self.position.craft_rating > 0
			add_error('insufficient_craft_rating')
			return false
		end
		target = Hex.in_game(self.position.game).at_id(location_id).first
		unless target
			add_error('invalid_location')
			return false
		end
		mana_spend = ((self.position.location.distance(target) * Character::TELEPORT_MANA_COST_MULTIPLIER) / self.position.craft_rating).round
		unless self.position.mana_points >= mana_spend
			add_error('insufficient_mana')
			return false
		end
		army = self.position.army 
		unless army 
			army = Position.create_army!(self.position.game, self.position, "#{self.position.name} Army")
			Unit.create_character_unit!(army, position)
		else
			if army.units.count > 1
				army = Position.create_army!(self.position.game, self.position, "#{self.position.name} Army")
				unit = self.position.unit 
				unit.update_attributes!(army: army)
			end
		end
		army.location = target
		army.save!
		self.position.use_mana_points!(mana_spend)
		add_report({target: target, mana_spend: mana_spend},'Teleport')
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end