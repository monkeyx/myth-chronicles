class ExploreDungeonAction < BaseAction
	
	PARAMETERS = {
			
	}
	
	POSITION_TYPE = [Character]
	SUBTYPE = ['Hero']

	DESCRIPTION = "<p>Explores the deepest known level of the dungeon at the current location.</p><p><strong>Action Points Cost</strong>: 4</p>"

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
		dungeon = Dungeon.in_game(self.position.game).at_loc(self.position.location).first
		unless dungeon 
			add_error('invalid_location')
			return false
		end
		level = self.position.level_explored(dungeon) + 1
		level = dungeon.max_levels if level > dungeon.max_levels
		challenge_type, success = dungeon.challenge(self.position, level)
		if success 
			renown = false
			if (rand(100) + 1) <= level 
				self.position.add_renown!(1)
				renown = true
			end
			gold = 0
			(1..level).each do
				gold += (rand(10) + 1)
			end
			self.position.add_gold!(gold)
			magic_item = nil
			if (rand(100) + 1) <= level 
				magic_item = Item.create_magic_item!(Character::CHARACTER_EQUIPMENT_SLOTS.sample, Character::CHARACTER_ATTRIBUTES.sample, (rand(level) + 1))
			end
			self.position.add_items!(magic_item, 1)
			self.position.set_level_explored!(dungeon, level)
			self.position.add_experience_points!(1)
			if renown && magic_item
				add_report({dungeon: dungeon, level: level.ordinalize, gold: gold, magic_item: magic_item, challenge_type: challenge_type}, 'SuccessWithRenownAndMagicItem')
			elsif magic_item
				add_report({dungeon: dungeon, level: level.ordinalize, gold: gold, magic_item: magic_item, challenge_type: challenge_type}, 'SuccessWithMagicItem')
			elsif renown 
				add_report({dungeon: dungeon, level: level.ordinalize, gold: gold, challenge_type: challenge_type}, 'SuccessWithRenown')
			else
				add_report({dungeon: dungeon, level: level.ordinalize, gold: gold, challenge_type: challenge_type}, 'Success')
			end
		else
			unless self.position.check_attribute(:armour_rating, (4 + (2 * level)))
				if self.position.incapacitated!
					add_report({dungeon: dungeon, level: level.ordinalize, challenge_type: challenge_type}, 'Incapacitated')
				else
					self.position.die!("exploring #{dungeon}")
					add_report({dungeon: dungeon, level: level.ordinalize, challenge_type: challenge_type}, 'Death')
				end
			else
				add_report({dungeon: dungeon, level: level.ordinalize, challenge_type: challenge_type}, 'Failure')
			end
		end
		return true
	end

	def action_point_cost 
		SLOW_ACTION
	end

end