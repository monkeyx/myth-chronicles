module PositionFactory
	def models
		@models ||= []
	end

	def setup_hero_user(confirmed=true)
		@hero = User.create!(name: "Hero Test User #{rand(1000000)}", email: "#{rand(10000)}@test.com", password: "password", password_confirmation: "password", character_type: "Hero", game: Game.first, confirmed: confirmed)
		SetupUser.setup!(@hero)
		@hero_character = @hero.character
		@hero_army = @hero.character.army
		@hero_settlement = @hero.character.settlements.first
		models << @hero
		@hero
	end

	def setup_lord_user(confirmed=true)
		@lord = User.create!(name: "Lord Test User #{rand(1000000)}", email: "#{rand(10000)}@test.com", password: "password", password_confirmation: "password", character_type: "Lord", game: Game.first, confirmed: confirmed)
		SetupUser.setup!(@lord)
		@lord_character = @lord.character
		@lord_army = @lord.character.army
		@lord_settlement = @lord.character.settlements.first
		models << @lord
		@lord
	end

	def setup_necromancer_user(confirmed=true)
		@necromancer = User.create!(name: "Necromancer Test User #{rand(1000000)}", email: "#{rand(10000)}@test.com", password: "password", password_confirmation: "password", character_type: "Necromancer", game: Game.first, confirmed: confirmed)
		SetupUser.setup!(@necromancer)
		@necromancer_character = @necromancer.character
		@necromancer_army = @necromancer.character.army
		@necromancer_settlement = @necromancer.character.settlements.first
		models << @necromancer
		@necromancer
	end

	def setup_dragon_user(confirmed=true)
		@dragon = User.create!(name: "Dragon Test User #{rand(1000000)}", email: "#{rand(10000)}@test.com", password: "password", password_confirmation: "password", character_type: "Dragon", game: Game.first, confirmed: confirmed)
		SetupUser.setup!(@dragon)
		@dragon_character = @dragon.character
		@dragon_army = @dragon.character.army
		@dragon_settlement = @dragon.character.settlements.first
		models << @dragon
		@dragon
	end

	def setup_two_users_at_same_location(user1type = 'Lord', user2type = 'Lord')
		@user1 = User.create!(name: "#{user1type} Test User #{rand(1000000)}", email: "#{rand(10000)}@test.com", password: "password", password_confirmation: "password", character_type: user1type, game: Game.first, confirmed: true)
		SetupUser.setup!(@user1)
		@user1_character = @user1.character
		@user1_army = @user1.character.army
		@user1_settlement = @user1.character.settlements.first
		models << @user1
		
		@user2 = User.create!(name: "#{user2type} Test User #{rand(1000000)}", email: "#{rand(10000)}@test.com", password: "password", password_confirmation: "password", character_type: user2type, game: Game.first, confirmed: true)
		SetupUser.setup!(@user2)
		@user2_character = @user2.character
		@user2_army = @user2.character.army
		@user2_settlement = @user2.character.settlements.first
		models << @user2

		@user2_army.location = @user1_army.location 
		@user2_army.save!
	end

	def setup_challenge(challenger=@user1_character, challengee=@user2_character)
		challenger.challenge!(challengee)
	end

	def setup_alliance(leader=@user1_character, name="Alliance #{rand(1000)}")
		alliance = Alliance.create!(leader: leader, name: name, game_time: leader.game.game_time)
		models << alliance 
		alliance
	end

	def ally_users(user1character=@user1_character, user2character=@user2_character)
		alliance = setup_alliance(user1character)
		alliance.join!(user2character)
		alliance
	end

	def setup_city(owner, size=Settlement::SIZE_HAMLET)
		hex = Hex.in_game(owner.game).unowned.any_of_terrains(Settlement::VALID_CITY_TERRAIN).limit(1).first
		city = Settlement.create_city!(owner.game, hex.location, "City #{rand(1000)}", hex.terrain_city_recruitment, size, owner)
		models << city
		city
	end

	def setup_army(owner)
		Position.create_army!(owner.game, owner)
	end

	def setup_guild(city, owner=nil)
		Position.create_settlement!(city.game, owner, 'Guild', city.location)
	end

	def setup_unit(army, race_item, training='', armour=nil, weapon=nil, mount=nil, transport=nil)
		unit = Unit.create_unit!(army, race_item)
		unit.training = training
		unit.armour = armour
		unit.weapon = weapon
		unit.mount = mount
		unit.transport = transport
		unit.save!
		unit
	end

	def setup_dungeon(game, location)
		Dungeon.create_dungeon!(game, location.x, location.y)
	end

	def give_items(position, item_name, quantity)
		position.add_items!(Item.named(item_name).first, quantity)
	end

	def create_magic_item(slot, rank=(rand(20)+1), stat=Character::CHARACTER_ATTRIBUTES.sample)
		Item.create_magic_item!(slot, stat, rank)
	end

	def give_magic_item(character, slot, rank=(rand(20)+1), stat=Character::CHARACTER_ATTRIBUTES.sample)
		item = create_magic_item(slot, rank, stat)
		character.add_items!(item, 1)
		item
	end

	def move_to_random_location(army)
		game = Game.first
		x = rand(game.map_size)
		y = rand(game.map_size)

		army.x = x 
		army.y = y
		army.save!
	end

	def possible_location(spatial)
		loc = spatial.location 
		loc + loc.possible_directions.sample
	end

	def clear_up_positions
		models.each {|m| m.destroy }
	end


end