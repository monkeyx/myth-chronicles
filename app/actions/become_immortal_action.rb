class BecomeImmortalAction < BaseAction

	PARAMETERS = {
			
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Attempts to reach immortality with this character. Must meet the <a href='/docs/immortality'>requirements</a>.</p><p><strong>Action Points Cost</strong>: 4</p>"

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
		unless (@settlement = self.position.at_own_settlement?)
			add_error('invalid_location')
			return false
		end
		success = case self.position.character_type
		when 'Hero'
			immortal_hero!
		when 'Lord'
			immortal_lord!
		when 'Necromancer'
			immortal_necromancer!
		when 'Dragon'
			immortal_dragon!
		end
		if success
			immortal = Immortal.new(name: self.position.name, character_type: self.position.character.character_type, game: self.position.game, user: self.position.user)
			immortal.game_time = self.position.game.game_time
			unless immortal.save
				set_errors immortal.errors
				return false
			end
			add_report
			return cataclysm!
		else
			return false
		end
	end

	def immortal_hero!
		unless self.position.armour.artefact?
			add_error('armour_not_artefact')
		end
		unless self.position.weapon.artefact?
			add_error('weapon_not_artefact')
		end
		unless self.position.ring.artefact?
			add_error('ring_not_artefact')
		end
		unless self.position.amulet.artefact?
			add_error('amulet_not_artefact')
		end
		return errors.count == 0
	end

	def immortal_lord!
		unless self.position.alliance && self.position.alliance.leader_id == self.position.id
			add_error('not_leader')
			return false
		end
		unless self.position.alliance.settlements.cities.capitals.count >= Character::IMMORTALITY_LORD_CAPITALS
			add_error('not_enough_capitals')
			return false
		end
		return true
	end

	def immortal_necromancer!
		army = self.position.army
		unless army 
			add_error('no_army')
			return false
		end
		Character::IMMORTALITY_NECROMANCER_ITEMS.keys.each do |item_name|
			unless self.position.item_count(item_name) >= Character::IMMORTALITY_NECROMANCER_ITEMS[item_name]
				add_error('insufficient_items')
				return false
			end
		end
		return false if errors.count > 0
		unless self.position.mana_points >= Character::IMMORTALITY_NECROMANCER_MANA
			add_error('insufficient_mana')
			return false
		end
		return true
	end

	def immortal_dragon!
		unless self.position.gold >= Character::IMMORTALITY_DRAGON_GOLD
			add_error('insufficient_gold')
			return false
		end
		return true
	end

	def cataclysm!
		@settlement.game.next_age! if @settlement.game.game_time.year > 100
		@settlement.cataclysm!
	end

	def action_point_cost 
		SLOW_ACTION
	end

end