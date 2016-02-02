require 'rails_helper'

RSpec.describe Api::ActionsController, type: :controller do
	include PositionFactory
	
	after(:each) do 
  		clear_up_positions
  	end

  	def post_action(position, action, params={}, user=position.user)
  		expect(user).to_not be_nil
  		expect(user.auth_token).to_not be_blank
  		sign_in :user, user
  		params.merge!({type: position.class.name, id: position.id, action_type: action})
  		post :create, params
  	end

  	def test_response(code,inspect=false)
  		unless response.response_code == code
  			puts response.body.inspect
  		end if inspect
  		expect(response).to have_http_status(code)
  	end

  	describe "Authorisation" do 
  		it "allows actions on owned position" do 
  			setup_hero_user
  			post_action(@hero_character,'ChangeName',{name: 'New Name'})
  			test_response(200)
  		end

  		it "doesn't allow actions on not owned position" do 
  			setup_hero_user
  			setup_dragon_user
  			post_action(@dragon_character,'ChangeName',{name: 'New Name'}, @hero)
  			test_response(403)
  		end

  		it "doesn't allow undefined actions on position" do 
  			setup_hero_user
  			post_action(@hero_character,'Noop')
  			test_response(405)
  		end
  	end

  	describe "Action Reports" do 
  		it "generates action report" do 
  			setup_hero_user
  			post_action(@hero_character,'ChangeName',{name: 'New Name'})
  			test_response(200)
  			expect(@hero_character.action_reports.count).to eq(1)
  		end
  	end

	describe "Accept Challenge" do
		it "successfully resolved combat" do 
			pending "combat engine"
			setup_two_users_at_same_location
			challenge = setup_challenge

			post_action(@user2_character,'AcceptChallenge',{challenge_id: challenge.id})
			test_response(200)

			@user1_character.reload
			@user2_character.reload
			expect(@user1_character.battle_reports.count).to eq(1)
			expect(@user2_character.battle_reports.count).to eq(1)
		end

		it "fails if challenger not in same location" do 
			setup_two_users_at_same_location
			challenge = setup_challenge

			move_to_random_location(@user1_army)

			expect(@user1_character.location).to_not eq(@user2_character.location)
			
			expect(challenge).to_not be_nil

			post_action(@user2_character,'AcceptChallenge',{challenge_id: challenge.id})
			test_response(422)
		end

		it "fails if challenge expired" do 
			setup_two_users_at_same_location
			challenge = setup_challenge

			game = Game.first
			game.game_time = game.game_time + 100
			game.save!
			
			challenge.reload
			challenge.game_time = game.game_time - (CharacterChallenge::CHALLENGE_EXPIRATION + 1)
			challenge.save!
			expect(challenge.expired?).to eq(true)

			post_action(@user2_character,'AcceptChallenge',{challenge_id: challenge.id})
			test_response(422)

			game.game_time = game.game_time - 100
			game.save
		end

		it "fails if not character" do 
			setup_two_users_at_same_location
			challenge = setup_challenge

			challenge = @user2_character.challenges.first
			post_action(@user2_army,'AcceptChallenge',{challenge_id: challenge.id})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location
			challenge = setup_challenge

			post_action(@user2_character,'AcceptChallenge',{})
			test_response(422)
		end
	end

	describe "Accept Membership" do
		it "successfully joined alliance" do 
			setup_two_users_at_same_location
			alliance = setup_alliance
			alliance.invite!(@user2_character)
			expect(alliance.invited?(@user2_character))

			post_action(@user2_character,'AcceptMembership',{alliance_id: alliance.id})
			test_response(200, true)
			expect(alliance.member?(@user2_character)).to_not be_nil
		end

		it "fails if not invitation to join alliance" do 
			setup_two_users_at_same_location
			alliance = setup_alliance

			post_action(@user2_character,'AcceptMembership',{alliance_id: alliance.id})
			test_response(422)
		end

		it "fails if already a member of an alliance" do 
			setup_two_users_at_same_location
			alliance1 = ally_users

			setup_lord_user
			alliance1.invite!(@lord_character)

			alliance2 = setup_alliance(@lord_character)

			post_action(@lord_character,'AcceptMembership',{alliance_id: alliance1.id})
			test_response(422, true)
		end

		it "fails if not character" do 
			setup_two_users_at_same_location
			alliance = setup_alliance
			alliance.invite!(@user2_character)

			post_action(@user2_army,'AcceptMembership',{alliance_id: alliance.id})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location
			alliance = setup_alliance
			alliance.invite!(@user2_character)

			post_action(@user2_character,'AcceptMembership',{})
			test_response(422)
		end
	end

	describe "Attack Army" do
		it "successfully resolves combat" do 
			pending "combat engine"
			setup_two_users_at_same_location

			post_action(@user1_army,'AttackArmy',{army_id: @user2_army.id})
			test_response(200)

			@user1_character.reload
			@user2_character.reload
			expect(@user1_character.battle_reports.count).to eq(1)
			expect(@user2_character.battle_reports.count).to eq(1)
		end

		it "fails if not an army" do 
			setup_two_users_at_same_location

			post_action(@user1_character,'AttackArmy',{army_id: @user2_army.id})
			test_response(422)
		end

		it "fails if army not at same location" do 
			setup_two_users_at_same_location

			move_to_random_location(@user2_army)

			post_action(@user1_character,'AttackArmy',{army_id: @user2_army.id})
			test_response(422)
		end

		it "fails if army is friendly" do 
			setup_two_users_at_same_location
			ally_users

			post_action(@user1_character,'AttackArmy',{army_id: @user2_army.id})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location

			post_action(@user1_army,'AttackArmy',{})
			test_response(422)
		end
	end

	describe "Become Immortal" do
		it "necromancer successfully becomes immortal" do 
			pending "cataclysm"
			setup_necromancer_user
			Character::IMMORTALITY_NECROMANCER_ITEMS.keys.each do |item_name|
				give_items(@necromancer_army, Character::IMMORTALITY_NECROMANCER_ITEMS[item_name])
			end

			@necromancer_character.craft_rating = Character::IMMORTALITY_NECROMANCER_MANA / 10
			@necromancer_character.mana_points = Character::IMMORTALITY_NECROMANCER_MANA
			@necromancer_character.save!
			
			post_action(@necromancer_character,'BecomeImmortal',{})
			test_response(200)

			expect(Character.where(id: @necromancer_character.id).count).to eq(0)
			expect(Immortal.where(name: @necromancer_character.name).count).to eq(1)

		end

		it "lord successfully becomes immortal" do 
			pending "cataclysm"
			leader = setup_lord_user
			alliance = setup_alliance(leader)
			(1..Character::IMMORTALITY_LORD_CAPITALS).each do
				member = setup_lord_user
				alliance.join!(member.character)
				setup_city(member.character, Settlement::SIZE_CAPITAL)
			end

			post_action(leader.character,'BecomeImmortal',{})
			test_response(200)

			expect(Character.where(id: @leader.id).count).to eq(0)
			expect(Immortal.where(name: @leader.name).count).to eq(1)
		end

		it "dragon successfully becomes immortal" do 
			pending "cataclysm"
			setup_dragon_user
			@dragon_character.gold = Character::IMMORTALITY_DRAGON_GOLD
			@dragon_character.save!

			post_action(@dragon_character,'BecomeImmortal',{})
			test_response(200)

			expect(Character.where(id: @dragon_character.id).count).to eq(0)
			expect(Immortal.where(name: @dragon_character.name).count).to eq(1)
		end

		it "hero successfully becomes immortal" do 
			pending "cataclysm"
			create_hero_user
			Character::CHARACTER_EQUIPMENT_SLOTS.each do |slot|
				give_magic_item(@hero_character, slot, Item::ARTEFACT_RANK)
			end

			post_action(@hero_character,'BecomeImmortal',{})
			test_response(200)

			expect(Character.where(id: @hero_character.id).count).to eq(0)
			expect(Immortal.where(name: @hero_character.name).count).to eq(1)
		end

		it "necromancer fails if insufficient items at location" do
			setup_necromancer_user

			@necromancer_character.craft_rating = Character::IMMORTALITY_NECROMANCER_MANA / 10
			@necromancer_character.mana_points = Character::IMMORTALITY_NECROMANCER_MANA
			@necromancer_character.save!
			
			post_action(@necromancer_character,'BecomeImmortal',{})
			test_response(422)
		end

		it "necromancer fails if insufficient mana" do
			setup_necromancer_user

			Character::IMMORTALITY_NECROMANCER_ITEMS.keys.each do |item_name|
				give_items(@necromancer_army, item_name, Character::IMMORTALITY_NECROMANCER_ITEMS[item_name])
			end
			
			post_action(@necromancer_character,'BecomeImmortal',{})
			test_response(422)
		end

		it "dragon fails for lack of gold" do 
			setup_dragon_user
			
			post_action(@dragon_character,'BecomeImmortal',{})
			test_response(422)
		end

		it "lord fails for not leading alliance with 10 capital cities" do 
			leader = setup_lord_user
			
			post_action(leader.character,'BecomeImmortal',{})
			test_response(422)
		end

		it "hero fails for not having artefacts in each equipment slot" do 
			setup_hero_user
			
			post_action(@hero_character,'BecomeImmortal',{})
			test_response(422)
		end

		it "fails if not character" do 
			setup_lord_user

			post_action(@lord_army,'BecomeImmortal',{})
			test_response(422)
		end
	end

	describe "Besiege Settlement" do
		it "successfully puts settlement under siege" do
			setup_two_users_at_same_location

			post_action(@user2_army,'BesiegeSettlement',{})
			test_response(200, true)

			@user1_settlement.reload
			@user2_army.reload
			expect(@user1_settlement.under_siege).to eq(true)
			expect(@user2_army.sieging).to eq(@user1_settlement)
		end

		it "fails if settlement not at same location" do 
			setup_two_users_at_same_location

			post_action(@user1_army,'BesiegeSettlement',{})
			test_response(422)
		end

		it "fails if not army" do 
			setup_two_users_at_same_location

			post_action(@user2_character,'BesiegeSettlement',{})
			test_response(422)
		end
	end

	describe "Buy Item" do
		it "successfully puts up a buy order" do 
			setup_hero_user
			item = Item.named('Wood').first

			post_action(@hero_settlement,'BuyItem',{item_id: item.id, quantity: 1000, price: 1})
			test_response(200)

			expect(Buy.where(position: @hero_settlement, item: item).count).to eq(1)
		end

		it "fails if not a valid item" do 
			setup_hero_user
			
			post_action(@hero_character,'BuyItem',{item_id: 99999999, quantity: 1000, price: 1})
			test_response(422)
		end

		it "fails if not a valid price" do 
			setup_hero_user
			item = Item.named('Wood').first

			post_action(@hero_character,'BuyItem',{item_id: item.id, quantity: 1000, price: -1})
			test_response(422)
		end

		it "fails if not a valid quantity" do 
			setup_hero_user
			item = Item.named('Wood').first

			post_action(@hero_character,'BuyItem',{item_id: item.id, quantity: -10, price: 1})
			test_response(422)
		end

		it "fails if not settlement" do 
			setup_hero_user
			item = Item.named('Wood').first

			post_action(@hero_character,'BuyItem',{item_id: item.id, quantity: 1000, price: 1})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_hero_user
			
			post_action(@hero_character,'BuyItem',{})
			test_response(422)
		end
	end

	describe "Capture Settlement" do
		it "successfully captures settlement" do
			setup_two_users_at_same_location
			@user1_army.destroy

			post_action(@user2_army,'CaptureSettlement',{})
			test_response(200)

			@user1_settlement.reload
			expect(@user1_settlement.owner).to eq(@user2_character)
		end

		it "fails if settlement type is not appropriate" do 
			setup_two_users_at_same_location('Lord','Necromancer')
			@user1_army.destroy

			expect(@user1_settlement.settlement_type).to_not eq(@user2_settlement.settlement_type)

			post_action(@user2_army,'CaptureSettlement',{})
			test_response(422, true)
		end

		it "fails if settlement is neutral" do 
			setup_lord_user
			neutral = Settlement.neutral.first
			@lord_army.location = neutral.location
			@lord_army.save!

			post_action(@lord_army,'CaptureSettlement',{})
			test_response(422)
		end

		it "fails if not an army" do 
			setup_two_users_at_same_location
			@user1_army.destroy

			post_action(@user2_character,'CaptureSettlement',{})
			test_response(422)
		end

		it "fails if settlement not at same location" do 
			setup_two_users_at_same_location
			@user2_army.destroy

			post_action(@user1_army,'CaptureSettlement',{})
			test_response(422)
		end

		it "fails if settlement is friendly" do
			setup_two_users_at_same_location
			ally_users
			@user1_army.destroy

			post_action(@user2_army,'CaptureSettlement',{})
			test_response(422)
		end

		it "fails if settlement has a friendly army guarding it at same location" do 
			setup_two_users_at_same_location
			@user1_army.guarding = true
			@user1_army.save!

			post_action(@user2_army,'CaptureSettlement',{})
			test_response(422)
		end
	end

	describe "Cast Spell" do
		it "successfully casts heal" do 
			setup_hero_user

			@hero_character.mana_points = 4
			@hero_character.save!

			unit = @hero_army.units.first
			unit.health = 75
			unit.save!

			expect(@hero_army.owner).to eq(@hero_character)

			post_action(@hero_character,'CastSpell',{spell: 'Heal', target: unit.id, mana_spend: 1})
			test_response(200, true)

			heal_points = (Character::HEAL_PER_MANA_CRAFT_FACTORS * 1 * @hero_character.craft_rating).to_i

			unit.reload
			@hero_character.reload
			expect(unit.health).to eq((75 + heal_points))
			expect(@hero_character.mana_points).to eq(3)
		end

		it "successfully casts ritual for mundane item" do 
			setup_necromancer_user

			@necromancer_character.mana_points = 10
			@necromancer_character.save!

			item = Item.named('Wood').first

			post_action(@necromancer_character,'CastSpell',{spell: 'Ritual', target: item.id, mana_spend: 5})
			test_response(200, true)

			@necromancer_settlement.reload
			@necromancer_character.reload

			quantity = (5 * @necromancer_character.craft_rating) / item.complexity

			expect(@necromancer_settlement.item_count(item)).to eq(quantity)
			expect(@necromancer_character.mana_points).to eq(5)
		end

		it "successfully casts ritual for magic item" do 
			setup_necromancer_user

			@necromancer_character.mana_points = 100
			@necromancer_character.save!

			post_action(@necromancer_character,'CastSpell',{spell: 'Ritual', target: 'armour', mana_spend: 100})
			test_response(200, true)

			@necromancer_settlement.reload
			@necromancer_character.reload

			item = Item.magical.last
			expect(@necromancer_character.item_count(item)).to eq(1)
			expect(@necromancer_character.mana_points).to eq(0)
			expect(@necromancer_character.craft_rating).to eq(9)
		end

		it "successfully casts scry" do 
			pending "scouting engine"
			setup_necromancer_user

			@necromancer_character.mana_points = 10
			@necromancer_character.save!

			location = possible_location(@necromancer_character.location)
			mana_cost = ((@hero_character.location.distance(location) * Character::SCRY_MANA_COST_MULTIPLIER) / @hero_character.craft_rating).round

			post_action(@necromancer_character,'CastSpell',{spell: 'Scry', target: location.id})
			test_response(200)

			@necromancer_character.reload
			expect(@necromancer_character.scouting_reports.count).to eq(1)
			expect(@necromancer_character.mana_points).to eq((6 - mana_cost))
		end

		it "successfully casts teleport" do 
			setup_hero_user

			@hero_character.mana_points = 10
			@hero_character.save!

			location = possible_location(@hero_character.location)
			expect(Hex.in_game(location.game).at_id(location.id).first).to_not be_nil

			mana_cost = ((@hero_character.location.distance(location) * Character::TELEPORT_MANA_COST_MULTIPLIER) / @hero_character.craft_rating).round

			post_action(@hero_character,'CastSpell',{spell: 'Teleport', target: location.id})
			test_response(200, true)

			@hero_character.reload
			expect(@hero_character.location).to eq(location)
			expect(@hero_character.mana_points).to eq((10 - mana_cost))
		end

		it "successfully casts bless" do 
			setup_lord_user

			@lord_character.mana_points = 10
			@lord_character.save!

			unit = @lord_army.units.first

			post_action(@lord_character,'CastSpell',{spell: 'Bless', target: unit.id, mana_spend: 4})
			test_response(200)

			unit.reload
			@lord_character.reload
			bless_rating = (Character::BLESS_PER_MANA_CRAFT_FACTORS * 4 * @lord_character.craft_rating).to_i
			expect(unit.bless_rating).to eq(bless_rating)
			expect(@lord_character.mana_points).to eq(6)
		end

		it "fails if unit to heal is not present" do
			setup_two_users_at_same_location
			ally_users

			@user1_character.mana_points = 4
			@user1_character.save!

			unit = @user2_army.units.first
			unit.health = 75
			unit.save!
			move_to_random_location(unit.army)

			post_action(@user1_character,'CastSpell',{spell: 'Heal', target: unit.id, mana_spend: 1})
			test_response(422)
		end

		it "fails if unit to heal is not damaged" do 
			setup_hero_user

			@hero_character.mana_points = 4
			@hero_character.save!

			unit = @hero_army.units.first

			post_action(@hero_character,'CastSpell',{spell: 'Heal', target: unit.id, mana_spend: 1})
			test_response(422)
		end

		it "fails if unit to heal is not friendly" do 
			setup_two_users_at_same_location
			
			@user1_character.mana_points = 4
			@user1_character.save!

			unit = @user2_army.units.first
			unit.health = 75
			unit.save!
			
			post_action(@user1_character,'CastSpell',{spell: 'Heal', target: unit.id, mana_spend: 1})
			test_response(422)
		end

		it "fails if unit to bless is not present" do 
			setup_two_users_at_same_location
			ally_users

			@user1_character.mana_points = 10
			@user1_character.save!

			unit = @user2_army.units.first
			move_to_random_location(unit.army)

			post_action(@user1_character,'CastSpell',{spell: 'Bless', target: unit.id, mana_spend: 4})
			test_response(422)
		end

		it "fails if unit to bless is not friendly" do 
			setup_two_users_at_same_location
			
			@user1_character.mana_points = 10
			@user1_character.save!

			unit = @user2_army.units.first
			
			post_action(@user1_character,'CastSpell',{spell: 'Bless', target: unit.id, mana_spend: 4})
			test_response(422)
		end

		it "fails to ritual one item if not enough mana" do 
			setup_necromancer_user

			@necromancer_character.mana_points = 1
			@necromancer_character.save!

			item = Item.where("complexity > #{(@necromancer_character.craft_rating)}").first

			post_action(@necromancer_character,'CastSpell',{spell: 'Ritual', target: item.id, mana_spend: 1})
			test_response(422)
		end

		it "fails to scry if mana is less than distance" do 
			setup_necromancer_user

			@necromancer_character.mana_points = 1
			@necromancer_character.craft_rating = 1
			@necromancer_character.save!

			location = possible_location(@necromancer_character.location)
			
			post_action(@necromancer_character,'CastSpell',{spell: 'Scry', target: location.id})
			test_response(422)
		end

		it "fails to teleport if mana is less than distance" do 
			setup_hero_user

			@hero_character.mana_points = 1
			@hero_character.craft_rating = 1
			@hero_character.save!

			location = possible_location(@hero_character.location)

			post_action(@hero_character,'CastSpell',{spell: 'Teleport', target: location.id})
			test_response(422)
		end

		it "fails if not enough mana points to cast the spell" do 
			setup_hero_user

			@hero_character.mana_points = 4
			@hero_character.save!

			unit = @hero_army.units.first
			unit.health = 75
			unit.save!

			post_action(@hero_character,'CastSpell',{spell: 'Heal', target: unit.id, mana_spend: 5})
			test_response(422)
		end

		it "fails to cast heal if dragon" do 
			setup_dragon_user

			@dragon_character.mana_points = 4
			@dragon_character.save!

			unit = @dragon_character.unit
			unit.health = 75
			unit.save!

			post_action(@dragon_character,'CastSpell',{spell: 'Heal', target: unit.id, mana_spend: 2})
			test_response(422)
		end

		it "fails to cast ritual if lord" do 
			setup_lord_user

			@lord_character.mana_points = 10
			@lord_character.save!

			item = Item.named('Wood').first

			post_action(@lord_character,'CastSpell',{spell: 'Ritual', target: item.id, mana_spend: 5})
			test_response(422)
		end

		it "fails to cast ritual if hero" do 
			setup_hero_user

			@hero_character.mana_points = 10
			@hero_character.save!

			item = Item.named('Wood').first

			post_action(@hero_character,'CastSpell',{spell: 'Ritual', target: item.id, mana_spend: 5})
			test_response(422)
		end

		it "fails to cast scry if hero" do 
			setup_hero_user

			@hero_character.mana_points = 10
			@hero_character.save!

			location = possible_location(@hero_character.location)
			
			post_action(@hero_character,'CastSpell',{spell: 'Scry', target: location.id})
			test_response(422)
		end

		it "fails to cast scry if lord" do 
			setup_lord_user

			@lord_character.mana_points = 10
			@lord_character.save!

			location = possible_location(@lord_character.location)
			
			post_action(@lord_character,'CastSpell',{spell: 'Scry', target: location.id})
			test_response(422)
		end

		it "fails to cast bless if necromancer" do
			setup_necromancer_user

			@necromancer_character.mana_points = 10
			@necromancer_character.save!

			unit = @necromancer_army.units.first

			post_action(@necromancer_character,'CastSpell',{spell: 'Bless', target: unit.id, mana_spend: 4})
			test_response(422)
		end

		it "fails to cast bless if dragon" do
			setup_dragon_user

			@dragon_character.mana_points = 10
			@dragon_character.save!

			unit = @dragon_army.units.first

			post_action(@dragon_character,'CastSpell',{spell: 'Bless', target: unit.id, mana_spend: 4})
			test_response(422)
		end

		it "fails to cast teleport if lord" do 
			setup_lord_user

			@lord_character.mana_points = 10
			@lord_character.save!

			location = possible_location(@lord_character.location)

			post_action(@lord_character,'CastSpell',{spell: 'Teleport', target: location.id})
			test_response(422)
		end

		it "fails to cast teleport if dragon" do 
			setup_dragon_user

			@dragon_character.mana_points = 10
			@dragon_character.save!

			location = possible_location(@dragon_character.location)

			post_action(@dragon_character,'CastSpell',{spell: 'Teleport', target: location.id})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_dragon_user

			post_action(@dragon_character,'CastSpell', {})
			test_response(422)
		end
	end

	describe "Challenge Character" do
		it "successfully challenges character" do 
			setup_two_users_at_same_location

			post_action(@user1_character,'ChallengeCharacter',{character_id: @user2_character.id})
			test_response(200)

			expect(@user1_character.challenges.count).to eq(1)
			expect(@user2_character.challenges.count).to eq(1)
		end

		it "fails if character isn't present" do
			setup_two_users_at_same_location

			move_to_random_location(@user2_army)

			post_action(@user1_character,'ChallengeCharacter',{character_id: @user2_character.id})
			test_response(422)
		end

		it "fails if character is friendly" do 
			setup_two_users_at_same_location
			ally_users

			post_action(@user1_character,'ChallengeCharacter',{character_id: @user2_character.id})
			test_response(422)
		end

		it "fails if not a character" do 
			setup_two_users_at_same_location

			post_action(@user1_army,'ChallengeCharacter',{character_id: @user2_character.id})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location

			post_action(@user1_character,'ChallengeCharacter',{})
			test_response(422)
		end
	end

	describe "Change Name" do 
		it "successfully changes position name" do 
			setup_hero_user
  			post_action(@hero_character,'ChangeName',{name: 'New Name'})
  			test_response(200)
  			@hero_character.reload
  			expect(@hero_character.name).to eq('New Name')
		end

		it "fails to change name if name is too short" do
			setup_hero_user
  			post_action(@hero_character,'ChangeName', {name: ''})
  			test_response(422)
		end

		it "fails to change name if name is too long" do
			setup_hero_user
  			post_action(@hero_character,'ChangeName', {name: '012345678901234567890123456789012345678901234567890'})
  			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_hero_user
  			post_action(@hero_character,'ChangeName')
  			test_response(422)
		end
	end

	describe "Create Army" do
		it "successfully from unit in army" do 
			setup_hero_user

			unit = @hero_army.units.first

			post_action(@hero_army,'CreateArmy', {name: 'New Army', unit_id: unit.id})
  			test_response(200)

  			unit.reload
  			@hero_character.reload
  			expect(@hero_character.armies.count).to eq(2)
  			expect(unit.army).to eq(@hero_character.armies.last)
		end

		it "fails if unit is not in army" do 
			setup_two_users_at_same_location

			unit = @user2_army.units.first

			post_action(@user1_army,'CreateArmy', {name: 'New Army', unit_id: unit.id})
  			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_hero_user

			post_action(@hero_army,'CreateArmy', {})
  			test_response(422)
		end
	end

	describe "Create Unit" do
		it "successfully with a new army" do 
			setup_lord_user

			@lord_character.gold = Unit::GOLD_COST_TO_CREATE
			@lord_character.save!
			item = @lord_settlement.recruitment_race_item
			give_items(@lord_settlement, item.name, Unit::MINIMUM_ITEM_QUANTITY)
			expect(@lord_settlement.item_count(item.name)).to eq(Unit::MINIMUM_ITEM_QUANTITY)

			post_action(@lord_settlement,'CreateUnit', {item_id: item.id})
  			test_response(200, true)

  			@lord_character.reload
  			expect(@lord_character.armies.count).to eq(2)
		end

		it "successfully and assigned it to an existing army at the same location" do 
			setup_lord_user

			@lord_character.gold = Unit::GOLD_COST_TO_CREATE
			@lord_character.save!
			item = @lord_settlement.recruitment_race_item
			give_items(@lord_settlement, item.name, Unit::MINIMUM_ITEM_QUANTITY)
			expect(@lord_settlement.item_count(item.name)).to eq(Unit::MINIMUM_ITEM_QUANTITY)

			unit_count = @lord_army.units.count

			post_action(@lord_settlement,'CreateUnit', {item_id: item.id, army_id: @lord_army.id })
  			test_response(200, true)

  			@lord_army.reload
  			expect(@lord_army.units.count).to eq((unit_count + 1))
		end

		it "successfully and costs 10 gold for humanoids" do 
			setup_lord_user

			@lord_character.gold = 100
			@lord_character.save!

			item = Item.named('Human').first
			give_items(@lord_settlement, item.name, Unit::MINIMUM_ITEM_QUANTITY)

			post_action(@lord_settlement,'CreateUnit', {item_id: item.id})
			test_response(200)

			@lord_character.reload
			expect(@lord_character.gold).to eq(100 - Unit::GOLD_COST_TO_CREATE)
		end

		it "successfully and costs 10 mana for elementals" do 
			setup_lord_user

			@lord_character.craft_rating = 10
			@lord_character.mana_points = 100
			@lord_character.save!

			item = Item.named('Imp').first
			give_items(@lord_settlement, item.name, Unit::MINIMUM_ITEM_QUANTITY)

			post_action(@lord_settlement,'CreateUnit', {item_id: item.id})
			test_response(200)

			@lord_character.reload
			expect(@lord_character.mana_points).to eq(100 - Unit::MANA_COST_TO_CREATE)
		end

		it "successfully and costs 10 mana for undead" do 
			setup_lord_user

			@lord_character.craft_rating = 10
			@lord_character.mana_points = 100
			@lord_character.save!

			item = Item.named('Skeleton').first
			give_items(@lord_settlement, item.name, Unit::MINIMUM_ITEM_QUANTITY)

			post_action(@lord_settlement,'CreateUnit', {item_id: item.id})
			test_response(200)

			@lord_character.reload
			expect(@lord_character.mana_points).to eq(100 - Unit::MANA_COST_TO_CREATE)
		end

		it "fails if the race item isn't present in the settlement" do 
			setup_lord_user

			@lord_character.gold = Unit::GOLD_COST_TO_CREATE
			@lord_character.save!
			item = @lord_settlement.recruitment_race_item
			
			post_action(@lord_settlement,'CreateUnit', {item_id: item.id})
  			test_response(422)
		end

		it "fails if gold isn't available to owner" do 
			setup_lord_user

			@lord_character.gold = 0
			@lord_character.save!

			item = @lord_settlement.recruitment_race_item
			give_items(@lord_settlement, item.name, Unit::MINIMUM_ITEM_QUANTITY)

			post_action(@lord_settlement,'CreateUnit', {item_id: item.id})
  			test_response(422)
		end

		it "fails if mana isn't available to owner" do 
			setup_lord_user

			@lord_character.mana_points = 0
			@lord_character.save!

			item = Item.named('Skeleton').first
			give_items(@lord_settlement, item.name, Unit::MINIMUM_ITEM_QUANTITY)

			post_action(@lord_settlement,'CreateUnit', {item_id: item.id})
  			test_response(422)
		end

		it "fails if not a settlement" do 
			setup_lord_user

			@lord_character.gold = Unit::GOLD_COST_TO_CREATE
			@lord_character.save!
			item = @lord_settlement.recruitment_race_item
			give_items(@lord_settlement, item.name, Unit::MINIMUM_ITEM_QUANTITY)

			post_action(@lord_army,'CreateUnit', {item_id: item.id})
  			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_lord_user

			@lord_character.gold = Unit::GOLD_COST_TO_CREATE
			@lord_character.save!
			item = @lord_settlement.recruitment_race_item
			give_items(@lord_settlement, item.name, Unit::MINIMUM_ITEM_QUANTITY)

			post_action(@lord_settlement,'CreateUnit', {})
  			test_response(422)
		end
	end

	describe "Distribute Goods" do
		it "successfully distributes trade goods" do 
			setup_lord_user

			@lord_settlement.population_loyalty = 50
			@lord_settlement.save!
			item = Item.trade_good.first
			give_items(@lord_settlement, item.name, @lord_settlement.population_size)

			post_action(@lord_settlement,'DistributeGoods', {item_id: item.id})
  			test_response(200)

  			@lord_settlement.reload
  			expect(@lord_settlement.population_loyalty).to eq(50 + Settlement::LOYALTY_BOOST_FOR_TRADE_GOODS)
		end

		it "fails if trade goods not present" do 
			setup_lord_user

			@lord_settlement.population_loyalty = 50
			@lord_settlement.save!
			item = Item.trade_good.first
			
			post_action(@lord_settlement,'DistributeGoods', {item_id: item.id})
  			test_response(422)
		end

		it "fails if not a city" do 
			setup_hero_user

			item = Item.trade_good.first
			give_items(@hero_settlement, item.name, 10000)

			post_action(@hero_settlement,'DistributeGoods', {item_id: item.id})
  			test_response(422)
		end

		it "fails if item isn't a trade good" do 
			setup_lord_user

			@lord_settlement.population_loyalty = 50
			@lord_settlement.save!
			item = Item.weapon.first
			give_items(@lord_settlement, item.name, @lord_settlement.population_size)

			post_action(@lord_settlement,'DistributeGoods', {item_id: item.id})
  			test_response(422)
		end

		it "fails if loyalty is at max" do 
			setup_lord_user

			@lord_settlement.population_loyalty = 100
			@lord_settlement.save!
			item = Item.trade_good.first
			give_items(@lord_settlement, item.name, @lord_settlement.population_size)

			post_action(@lord_settlement,'DistributeGoods', {item_id: item.id})
  			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_lord_user

			@lord_settlement.population_loyalty = 50
			@lord_settlement.save!
			item = Item.trade_good.first
			give_items(@lord_settlement, item.name, @lord_settlement.population_size)

			post_action(@lord_settlement,'DistributeGoods', {})
  			test_response(422)
		end
	end

	describe "Equip Magic" do
		it "successfully equips armour" do 
			setup_hero_user

			item = give_magic_item(@hero_character, :armour)

			post_action(@hero_character,'EquipMagic', {item_id: item.id})
  			test_response(200, true)

  			@hero_character.reload
  			expect(@hero_character.armour).to eq(item)
		end

		it "successfully equips weapon" do 
			setup_hero_user

			item = give_magic_item(@hero_character, :weapon)

			post_action(@hero_character,'EquipMagic', {item_id: item.id})
  			test_response(200, true)

  			@hero_character.reload
  			expect(@hero_character.weapon).to eq(item)
		end

		it "successfully equips ring" do 
			setup_hero_user

			item = give_magic_item(@hero_character, :ring)

			post_action(@hero_character,'EquipMagic', {item_id: item.id})
  			test_response(200, true)

  			@hero_character.reload
  			expect(@hero_character.ring).to eq(item)
		end

		it "successfully equips amulet" do
			setup_hero_user

			item = give_magic_item(@hero_character, :amulet)

			post_action(@hero_character,'EquipMagic', {item_id: item.id})
  			test_response(200, true)

  			@hero_character.reload
  			expect(@hero_character.amulet).to eq(item)
		end

		it "fails if not a character" do 
			setup_hero_user

			item = give_magic_item(@hero_character, :amulet)

			post_action(@hero_army,'EquipMagic', {item_id: item.id})
  			test_response(422)
		end

		it "fails if doesn't have the magic item" do 
			setup_hero_user

			item = Item.create_magic_item!(:armour, :strength_rating, 1)

			post_action(@hero_character,'EquipMagic', {item_id: item.id})
  			test_response(422)
		end

		it "fails if lord and trying to use a ring" do 
			setup_lord_user

			item = give_magic_item(@lord_character, :ring)

			post_action(@lord_character,'EquipMagic', {item_id: item.id})
  			test_response(422)
		end

		it "fails if necromancer and trying to use armour" do
			setup_necromancer_user

			item = give_magic_item(@necromancer_character, :armour)

			post_action(@necromancer_character,'EquipMagic', {item_id: item.id})
  			test_response(422)
		end

		it "fails if dragon and trying to use weapon" do 
			setup_dragon_user

			item = give_magic_item(@dragon_character, :weapon)

			post_action(@dragon_character,'EquipMagic', {item_id: item.id})
  			test_response(422)
		end

		it "fails if dragon and trying to use armour" do 
			setup_dragon_user

			item = give_magic_item(@dragon_character, :armour)

			post_action(@dragon_character,'EquipMagic', {item_id: item.id})
  			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_hero_user

			item = give_magic_item(@hero_character, :amulet)

			post_action(@hero_character,'EquipMagic', {})
  			test_response(422)
		end
	end

	describe "Equip Unit" do
		it "successfully equips armour" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.armour.first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(200)

			unit.reload
			expect(unit.armour).to eq(item)
		end

		it "successfully equips weapon" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.weapon.first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(200)

			unit.reload
			expect(unit.weapon).to eq(item)
		end

		it "successfully equips mount" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.beast.first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(200)

			unit.reload
			expect(unit.mount).to eq(item)
		end

		it "successfully equips transport" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.vehicle.first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(200)

			unit.reload
			expect(unit.transport).to eq(item)
		end

		it "successfully equips siege equipment" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.siege_equipment.first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(200)

			unit.reload
			expect(unit.siege_equipment).to eq(item)
		end

		it "fails if not a unit" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.armour.first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: @lord_character.id})
			test_response(422)
		end

		it "fails if unit is not in this army" do 
			setup_two_users_at_same_location

			unit = setup_unit(@user1_army, @user1_settlement.recruitment_race_item)
			item = Item.armour.first
			give_items(@user2_army, item.name, 100)

			post_action(@user2_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(422)
		end

		it "fails if equiping armour and elemental" do 
			setup_dragon_user

			unit = setup_unit(@dragon_army, @dragon_settlement.recruitment_race_item)
			item = Item.armour.first
			give_items(@dragon_army, item.name, 100)

			post_action(@dragon_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(422)
		end

		it "fails if equiping weapon and elemental" do 
			setup_dragon_user

			unit = setup_unit(@dragon_army, @dragon_settlement.recruitment_race_item)
			item = Item.weapon.first
			give_items(@dragon_army, item.name, 100)

			post_action(@dragon_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(422)
		end

		it "fails if equipping mount and elemental" do 
			setup_dragon_user

			unit = setup_unit(@dragon_army, @dragon_settlement.recruitment_race_item)
			item = Item.beast.first
			give_items(@dragon_army, item.name, 100)

			post_action(@dragon_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(422)
		end

		it "fails if equipping mount and undead" do 
			setup_necromancer_user

			unit = setup_unit(@necromancer_army, @necromancer_settlement.recruitment_race_item)
			item = Item.beast.first
			give_items(@necromancer_army, item.name, 100)

			post_action(@necromancer_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(422)
		end

		it "fails if equipping invalid item" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.trade_good.first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(422)
		end

		it "fails if equipping bow without training in archery" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.named('Bow').first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(422)
		end

		it "succeeds if equipping bow with training in archery" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item, 'Archery')
			item = Item.named('Bow').first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(200)
		end

		it "fails if equipping plate mail without training in armoured" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.named('Plate mail').first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(422)
		end

		it "succeeds if equipping plate mail with training in armoured" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item, 'Armoured')
			item = Item.named('Plate mail').first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(200)
		end

		it "fails if equipping crossbow without training in machinery" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.named('Crossbow').first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(422)
		end

		it "succeeds if equipping crossbow with training in machinery" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item, 'Machinery')
			item = Item.named('Crossbow').first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(200)
		end

		it "fails if equipping lance without training in mobile and already equipped with a mount" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.named('Lance').first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(422)
		end

		it "succeeds if equipping lance with training in mobile and already equipped with a mount" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item, 'Mobile')
			unit.mount = Item.named('Horse').first
			unit.save!
			item = Item.named('Lance').first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {item_id: item.id, unit_id: unit.id})
			test_response(200)
		end

		it "fails if not all parameters" do 
			setup_lord_user

			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			item = Item.armour.first
			give_items(@lord_army, item.name, 100)

			post_action(@lord_army, 'EquipUnit', {})
			test_response(422)
		end
	end

	describe "Expand City" do
		it "successfully expands a city" do 
			setup_lord_user

			@lord_settlement.population_size = 1000
			@lord_settlement.population_loyalty = 100
			@lord_settlement.save!
			give_items(@lord_settlement, @lord_settlement.recruitment_race_item.name, 1000)
			give_items(@lord_settlement, 'Wood', 1000)
			give_items(@lord_settlement, 'Stone', 1000)

			post_action(@lord_settlement, 'ExpandCity', {quantity: 1000})
			test_response(200)

			@lord_settlement.reload
			expect(@lord_settlement.population_size).to eq(2000)
		end

		it "fails if not a city" do 
			setup_necromancer_user

			give_items(@necromancer_settlement, Item.humanoid.first.name, 1000)
			give_items(@necromancer_settlement, 'Wood', 1000)
			give_items(@necromancer_settlement, 'Stone', 1000)

			post_action(@necromancer_settlement, 'ExpandCity', {quantity: 1000})
			test_response(422)
		end

		it "fails if item isn't of the right race" do 
			setup_lord_user

			@lord_settlement.population_size = 1000
			@lord_settlement.save!
			item = Item.humanoid.where(["race <> ?", @lord_settlement.recruitment_race_item.race]).first
			give_items(@lord_settlement, item.name, 1000)
			give_items(@lord_settlement, 'Wood', 1000)
			give_items(@lord_settlement, 'Stone', 1000)

			post_action(@lord_settlement, 'ExpandCity', {quantity: 1000})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_lord_user

			@lord_settlement.population_size = 1000
			@lord_settlement.population_loyalty = 100
			@lord_settlement.save!
			give_items(@lord_settlement, @lord_settlement.recruitment_race_item.name, 1000)
			give_items(@lord_settlement, 'Wood', 1000)
			give_items(@lord_settlement, 'Stone', 1000)

			post_action(@lord_settlement, 'ExpandCity', {})
			test_response(422)
		end
	end

	describe "Explore Dungeon" do
		it "successfully explores a dungeon" do 
			setup_hero_user

			dungeon = setup_dungeon(@hero.game, @hero_character.location)

			post_action(@hero_character, 'ExploreDungeon', {level: 1})
			test_response(200, true)

			@hero_character.reload
			expect(@hero_character.dungeon_exploreds.count).to eq(1)
		end

		it "fails if not a hero" do 
			setup_lord_user

			dungeon = setup_dungeon(@lord.game, @lord_character.location)

			post_action(@lord_character, 'ExploreDungeon', {level: 1})
			test_response(422)
		end

		it "fails if not in same location of dungeon" do 
			setup_hero_user

			dungeon = setup_dungeon(@hero.game, @hero_character.location)

			move_to_random_location(@hero_army)

			post_action(@hero_character, 'ExploreDungeon', {level: 1})
			test_response(422)
		end

		it "fails if level to explore is too high" do 
			setup_hero_user

			dungeon = setup_dungeon(@hero.game, @hero_character.location)

			post_action(@hero_character, 'ExploreDungeon', {level: 2})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_hero_user

			dungeon = setup_dungeon(@hero.game, @hero_character.location)

			post_action(@hero_character, 'ExploreDungeon', {})
			test_response(422)
		end
	end

	describe "Form Alliance" do
		it "successfully forms an alliance" do 
			setup_lord_user

			post_action(@lord_character, 'FormAlliance', {name: 'New Alliance'})
			test_response(200)

			@lord_character.reload
			expect(@lord_character.alliance).to_not be_nil
		end

		it "fails if not a lord" do 
			setup_hero_user

			post_action(@hero_character, 'FormAlliance', {name: 'New Alliance'})
			test_response(422)
		end

		it "fails if already part of an alliance" do 
			setup_lord_user
			setup_alliance(@lord_character)

			post_action(@lord_character, 'FormAlliance', {name: 'New Alliance'})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_lord_user

			post_action(@lord_character, 'FormAlliance', {})
			test_response(422)
		end
	end

	describe "Form Settlement" do
		it "successfully forms a city" do 
			setup_lord_user

			move_to_random_location(@lord_army)
			while !Settlement::VALID_CITY_TERRAIN.include?(@lord_army.terrain) || @lord_army.hex.territory do
				move_to_random_location(@lord_army)
			end
			@lord_army.save!

			give_items(@lord_army, 'Wood', 500)
			give_items(@lord_army, 'Stone', 500)
			give_items(@lord_army, Terrain::CITY_TERRAIN_RECRUITMENT[@lord_army.terrain], 50)

			post_action(@lord_army, 'FormSettlement', {name: 'New City'})
			test_response(200, true)

			@lord_character.reload
			@lord_army.reload
			expect(@lord_character.settlements.count).to eq(2)
			expect(@lord_army.item_count(Item.named('Wood').first)).to eq(0)
			expect(@lord_army.item_count(Item.named('Stone').first)).to eq(0)
			expect(@lord_army.item_count(Item.named(Terrain::CITY_TERRAIN_RECRUITMENT[@lord_army.terrain]).first)).to eq(0)
		end

		it "successfully forms a guild" do 
			setup_hero_user

			neutral = Settlement.neutral.first
			neutral.guild.destroy

			@hero_army.location = neutral.location 
			@hero_army.save!

			@hero_character.gold = 1000
			@hero_character.save!

			settlement_count = @hero_character.settlements.count

			give_items(@hero_army, 'Stone', 500)
			
			post_action(@hero_army, 'FormSettlement', {name: 'New Guild'})
			test_response(200, true)

			@hero_character.reload
			@hero_army.reload
			expect(@hero_character.settlements.count).to eq(settlement_count + 1)
			expect(@hero_army.item_count(Item.named('Stone').first)).to eq(0)
			expect(@hero_character.gold).to eq(0)
		end

		it "successfully forms a tower" do 
			setup_necromancer_user

			move_to_random_location(@necromancer_army)
			while !Settlement::VALID_TOWER_TERRAIN.include?(@necromancer_army.terrain) || @necromancer_army.hex.territory do
				move_to_random_location(@necromancer_army)
			end
			@necromancer_army.save!

			give_items(@necromancer_army, 'Stone', 500)

			@necromancer_character.mana_points = 100
			@necromancer_character.save!
			
			post_action(@necromancer_army, 'FormSettlement', {name: 'New Tower'})
			test_response(200, true)

			@necromancer_character.reload
			@necromancer_army.reload
			expect(@necromancer_character.settlements.count).to eq(2)
			expect(@necromancer_character.mana_points).to eq(0)
			expect(@necromancer_character.item_count(Item.named('Stone').first)).to eq(0)
		end

		it "successfully forms a lair" do
			setup_dragon_user

			move_to_random_location(@dragon_army)
			while !Settlement::VALID_LAIR_TERRAIN.include?(@dragon_army.terrain) || @dragon_army.hex.territory do
				move_to_random_location(@dragon_army)
			end
			@dragon_army.save!

			@dragon_character.craft_rating = 20
			@dragon_character.mana_points = 200
			@dragon_character.save!
			
			post_action(@dragon_army, 'FormSettlement', {name: 'New Tower'})
			test_response(200, true)

			@dragon_character.reload
			expect(@dragon_character.settlements.count).to eq(2)
			expect(@dragon_character.mana_points).to eq(0)
		end

		it "fails if not an army" do
			setup_lord_user

			move_to_random_location(@lord_army)
			while !Settlement::VALID_CITY_TERRAIN.include?(@lord_army.terrain) || @lord_army.hex.territory do
				move_to_random_location(@lord_army)
			end
			@lord_army.save!

			give_items(@lord_army, 'Wood', 500)
			give_items(@lord_army, 'Stone', 500)
			give_items(@lord_army, Terrain::CITY_TERRAIN_RECRUITMENT[@lord_army.terrain], 50)

			post_action(@lord_character, 'FormSettlement', {name: 'New City'})
			test_response(422)
		end

		it "fails if army doesn't have items for a city" do 
			setup_lord_user

			move_to_random_location(@lord_army)
			while !Settlement::VALID_CITY_TERRAIN.include?(@lord_army.terrain) || @lord_army.hex.territory do
				move_to_random_location(@lord_army)
			end
			@lord_army.save!

			post_action(@lord_army, 'FormSettlement', {name: 'New City'})
			test_response(422)
		end

		it "fails if army doesn't have items for a guild" do 
			setup_hero_user

			neutral = Settlement.neutral.first
			neutral.guild.destroy

			@hero_army.location = neutral.location 
			@hero_army.save!

			@hero_character.gold = 1000
			@hero_character.save!

			post_action(@hero_army, 'FormSettlement', {name: 'New Guild'})
			test_response(422)
		end

		it "fails if army doesn't have items for a tower" do 
			setup_necromancer_user

			move_to_random_location(@necromancer_army)
			while !Settlement::VALID_TOWER_TERRAIN.include?(@necromancer_army.terrain) || @necromancer_army.hex.territory do
				move_to_random_location(@necromancer_army)
			end
			@necromancer_army.save!

			@necromancer_character.mana_points = 100
			@necromancer_character.save!
			
			post_action(@necromancer_army, 'FormSettlement', {name: 'New Tower'})
			test_response(422)
		end

		it "fails if army doesn't have mana for a lair" do 
			setup_dragon_user

			move_to_random_location(@dragon_army)
			while !Settlement::VALID_LAIR_TERRAIN.include?(@dragon_army.terrain) || @dragon_army.hex.territory do
				move_to_random_location(@dragon_army)
			end
			@dragon_army.save!

			@dragon_character.craft_rating = 20
			@dragon_character.mana_points = 100
			@dragon_character.save!
			
			post_action(@dragon_army, 'FormSettlement', {name: 'New Tower'})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_lord_user

			move_to_random_location(@lord_army)
			while !Settlement::VALID_CITY_TERRAIN.include?(@lord_army.terrain) || @lord_army.hex.territory do
				move_to_random_location(@lord_army)
			end
			@lord_army.save!

			give_items(@lord_army, 'Wood', 500)
			give_items(@lord_army, 'Stone', 500)
			give_items(@lord_army, Terrain::CITY_TERRAIN_RECRUITMENT[@lord_army.terrain], 50)

			post_action(@lord_army, 'FormSettlement', {})
			test_response(422)
		end
	end

	describe "Give Permission" do
		it "successfully gives full permission" do 
			setup_two_users_at_same_location

			post_action(@user1_settlement, 'GivePermissions', {target_id: @user2_army.id, full: true})
			test_response(200, true)

			@user1_settlement.reload
			expect(@user1_settlement.full_permission?(@user2_army)).to be(true)
		end

		it "successfully gives pickup permission" do 
			setup_two_users_at_same_location

			post_action(@user1_settlement, 'GivePermissions', {target_id: @user2_army.id, item_id: 1, quantity: 100})
			test_response(200, true)

			@user1_settlement.reload
			expect(@user1_settlement.pickup_permission(@user2_army, Item.where(id: 1).first)).to be(100)
		end

		it "fails if not a settlement" do 
			setup_two_users_at_same_location

			post_action(@user1_army, 'GivePermissions', {target_id: @user2_army.id, full: true})
			test_response(422)
		end

		it "fails is not a character or army" do 
			setup_two_users_at_same_location

			post_action(@user1_settlement, 'GivePermissions', {target_id: @user2_settlement.id, full: true})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location

			post_action(@user1_settlement, 'GivePermissions', {})
			test_response(422)
		end
	end

	describe "Guard Settlement" do
		it "successfully guards a settlement" do
			setup_lord_user

			post_action(@lord_army, 'GuardSettlement', {})
			test_response(200)

			@lord_army.reload
			expect(@lord_army.guarding).to be(true)
		end

		it "fails if not an army" do 
			setup_lord_user

			post_action(@lord_character, 'GuardSettlement', {})
			test_response(422)
		end

		it "fails if not at settlement" do 
			setup_lord_user

			move_to_random_location(@lord_army)

			post_action(@lord_army, 'GuardSettlement', {})
			test_response(422)
		end
	end

	describe "Improve Defences" do
		it "successfully improved defence rating of city" do 
			setup_lord_user

			give_items(@lord_settlement, 'Wood', 450)
			give_items(@lord_settlement, 'Stone', 450)

			post_action(@lord_settlement, 'ImproveDefences', {})
			test_response(200)

			@lord_settlement.reload
			expect(@lord_settlement.defence_rating).to eq(3)
		end

		it "successfully improved defence rating of tower using materials" do 
			setup_necromancer_user

			give_items(@necromancer_settlement, 'Wood', 200)
			give_items(@necromancer_settlement, 'Stone', 200)

			post_action(@necromancer_settlement, 'ImproveDefences', {})
			test_response(200)

			@necromancer_settlement.reload
			expect(@necromancer_settlement.defence_rating).to eq(2)
		end

		it "successfully improved defence rating of lair using materials" do 
			setup_dragon_user

			give_items(@dragon_settlement, 'Wood', 200)
			give_items(@dragon_settlement, 'Stone', 200)

			post_action(@dragon_settlement, 'ImproveDefences', {})
			test_response(200)

			@dragon_settlement.reload
			expect(@dragon_settlement.defence_rating).to eq(1)
		end

		it "fails if not settlement" do 
			setup_lord_user

			give_items(@lord_settlement, 'Wood', 450)
			give_items(@lord_settlement, 'Stone', 450)

			post_action(@lord_army, 'ImproveDefences', {})
			test_response(422)
		end

		it "fails if insufficient resources" do 
			setup_lord_user

			give_items(@lord_settlement, 'Wood', 10)
			give_items(@lord_settlement, 'Stone', 25)

			post_action(@lord_settlement, 'ImproveDefences', {})
			test_response(422)
		end
	end

	describe "Inspire City" do
		it "successfully improved loyalty" do 
			setup_lord_user

			@lord_character.renown = 1
			@lord_character.save!

			@lord_settlement.population_loyalty = 75
			@lord_settlement.save!

			post_action(@lord_character, 'InspireCity',{})
			test_response(200)

			@lord_character.reload
			@lord_settlement.reload 

			expect(@lord_character.renown).to eq(0)
			expect(@lord_settlement.population_loyalty).to eq(85)
		end

		it "fails if not character" do 
			setup_lord_user

			@lord_character.renown = 1
			@lord_character.save!

			@lord_settlement.population_loyalty = 75
			@lord_settlement.save!

			post_action(@lord_settlement, 'InspireCity',{})
			test_response(422)
		end

		it "fails if not in city" do 
			setup_lord_user

			@lord_character.renown = 1
			@lord_character.save!

			@lord_settlement.population_loyalty = 75
			@lord_settlement.save!

			move_to_random_location(@lord_army)
			@lord_army.save!

			post_action(@lord_character, 'InspireCity',{})
			test_response(422)
		end

		it "fails if no renown to spend" do 
			setup_lord_user

			@lord_character.renown = 0
			@lord_character.save!

			@lord_settlement.population_loyalty = 75
			@lord_settlement.save!

			post_action(@lord_character, 'InspireCity',{})
			test_response(422)
		end

		it "fails if loyalty at maximum" do 
			setup_lord_user

			@lord_character.renown = 1
			@lord_character.save!

			@lord_settlement.population_loyalty = 100
			@lord_settlement.save!

			post_action(@lord_character, 'InspireCity',{})
			test_response(422)
		end
	end

	describe "Invite Member" do
		it "successfully invites a character to an alliance if leader" do 
			setup_two_users_at_same_location
			alliance = setup_alliance

			post_action(@user1_character, 'InviteMember', {character_id: @user2_character.id})
			test_response(200)

			alliance.reload
			expect(alliance.invited?(@user2_character)).to_not be_nil
		end

		it "successfully invites a character to an alliance if member with invite rights" do 
			setup_two_users_at_same_location
			alliance = ally_users
			alliance.give_invite_rights!(@user2_character)
			setup_dragon_user

			post_action(@user2_character, 'InviteMember', {character_id: @dragon_character.id})
			test_response(200)

			alliance.reload
			expect(alliance.invited?(@dragon_character)).to_not be_nil
		end

		it "fails if target isn't a chaaracter" do 
			setup_two_users_at_same_location
			alliance = setup_alliance

			post_action(@user1_character, 'InviteMember', {character_id: @user2_army.id})
			test_response(422)
		end

		it "fails if not a character" do 
			setup_two_users_at_same_location
			alliance = setup_alliance

			post_action(@user1_army, 'InviteMember', {character_id: @user2_character.id})
			test_response(422)
		end

		it "fails if not a member with invite rights" do 
			setup_two_users_at_same_location
			alliance = ally_users

			setup_dragon_user

			post_action(@user2_character, 'InviteMember', {character_id: @dragon_character.id})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location
			alliance = setup_alliance

			post_action(@user1_character, 'InviteMember', {})
			test_response(422)
		end
	end

	describe "Kick Member" do
		it "successfully kicks an alliance member if alliance leader" do 
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user1_character, 'KickMember', {character_id: @user2_character.id})
			test_response(200, true)
			
			alliance.reload
			expect(alliance.member?(@user2_character)).to be_nil
		end

		it "successfully kicks an alliance member if member with kick rights" do 
			setup_two_users_at_same_location
			alliance = ally_users
			alliance.give_kick_rights!(@user2_character)
			setup_dragon_user
			alliance.join!(@dragon_character)

			post_action(@user2_character, 'KickMember', {character_id: @user2_character.id})
			test_response(200)
			
			alliance.reload
			expect(alliance.member?(@user2_character)).to be_nil
		end

		it "fails if target isn't an alliance member" do 
			setup_two_users_at_same_location
			alliance = setup_alliance

			post_action(@user1_character, 'KickMember', {character_id: @user2_character.id})
			test_response(422)
			
		end

		it "fails if don't have kick rights" do 
			setup_two_users_at_same_location
			alliance = ally_users
			
			setup_dragon_user
			alliance.join!(@dragon_character)

			post_action(@user2_character, 'KickMember', {character_id: @user2_character.id})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user1_character, 'KickMember', {})
			test_response(422)
		end
	end

	describe "Leave Alliance" do
		it "successfully leaves an alliance" do 
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user2_character, 'LeaveAlliance', {})
			test_response(200)

			alliance.reload
			expect(alliance.member?(@user2_character)).to be_nil
		end

		it "successfully transfers alliance leadership if leaving" do
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user1_character, 'LeaveAlliance', {})
			test_response(200)

			alliance.reload
			expect(alliance.member?(@user1_character)).to be_nil
			expect(alliance.leader?(@user2_character)).to_not be_nil
		end

		it "fails if not in an alliance" do 
			setup_two_users_at_same_location
			alliance = setup_alliance

			post_action(@user2_character, 'LeaveAlliance', {})
			test_response(422)
		end
	end

	describe "Leave Army" do
		it "successfully leaves to join another army" do 
			setup_lord_user

			army2 = setup_army(@lord_character)

			post_action(@lord_character, 'LeaveArmy', {army_id: army2.id})
			test_response(200)

			@lord_character.reload
			
			expect(@lord_character.army).to eq(army2)
		end

		it "successfully leaves to join new army" do 
			setup_lord_user

			post_action(@lord_character, 'LeaveArmy', {})
			test_response(200)

			@lord_character.reload
			
			expect(@lord_character.army).to_not eq(@lord_army)
		end

		it "fails if not a character" do 
			setup_lord_user

			post_action(@lord_army, 'LeaveArmy', {})
			test_response(422)
		end

		it "fails if other army is not in same location" do 
			setup_lord_user

			army2 = setup_army(@lord_character)
			move_to_random_location(army2)
			army2.save!

			post_action(@lord_character, 'LeaveArmy', {army_id: army2.id})
			test_response(422)
		end
	end

	describe "Move Army" do
		it "successfully moves army on land" do 
			setup_lord_user

			old_location = @lord_army.location
			hex = Hex.in_game(@lord.game).around(@lord_army.location).not_terrain('Sea').first
			if hex.difficult? || hex.impassable?
				hex.terrain = "Plains"
				hex.save!
			end
			direction = @lord_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			#raise "#{@lord_army.location} -> #{hex} : #{direction}"

			post_action(@lord_army, 'MoveArmy', {direction: direction})
			test_response(200, true)

			@lord_army.reload
			expect(@lord_army.location).to_not eq(old_location)
			expect(@lord_army.location).to eq(hex.location)
		end

		it "successfully moves army on sea" do 
			setup_lord_user

			old_location = @lord_army.location

			@lord_army.units.each {|unit| unit.transport = Item.named('Boat').first; unit.save! }
			@lord_army.save!
			hex = Hex.in_game(@lord.game).around(@lord_army.location).first
			hex.terrain = 'Sea'
			hex.save!
			direction = @lord_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			#raise "#{@lord_army.location} -> #{hex} : #{direction}"

			post_action(@lord_army, 'MoveArmy', {direction: direction})
			test_response(200, true)

			@lord_army.reload
			expect(@lord_army.location).to_not eq(old_location)
			expect(@lord_army.location).to eq(hex.location)
		end

		it "fails if not an army" do 
			setup_lord_user

			hex = Hex.in_game(@lord.game).around(@lord_army.location).not_terrain('Sea').first
			if hex.difficult? || hex.impassable?
				hex.terrain = "Plains"
				hex.save!
			end
			direction = @lord_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			post_action(@lord_character, 'MoveArmy', {direction: direction})
			test_response(422)
		end

		it "fails if moving to impassable terrain without air movement" do 
			setup_lord_user

			hex = Hex.in_game(@lord.game).around(@lord_army.location).first
			hex.terrain = 'Volcano'
			hex.save!
			direction = @lord_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			post_action(@lord_army, 'MoveArmy', {direction: direction})
			test_response(422)
		end

		it "fails if moving to sea without sea movement" do 
			setup_lord_user

			hex = Hex.in_game(@lord.game).around(@lord_army.location).first
			hex.terrain = 'Sea'
			hex.save!
			direction = @lord_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			post_action(@lord_army, 'MoveArmy', {direction: direction})
			test_response(422)
		end

		it "fails if moving immobile army" do 
			setup_lord_user

			give_items(@lord_army, 'Wood', 500000)
			expect(@lord_army.item_count('Wood')).to eq(500000)
			@lord_army.reload
			#raise "Land: #{@lord_army.land_capacity} / Air: #{@lord_army.air_capacity}"
			expect(@lord_army.immobile?).to be(true)

			hex = Hex.in_game(@lord.game).around(@lord_army.location).not_terrain('Sea').first
			if hex.difficult? || hex.impassable?
				hex.terrain = "Plains"
				hex.save!
			end
			direction = @lord_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			post_action(@lord_army, 'MoveArmy', {direction: direction})
			test_response(422)
		end

		it "successfully uses up right AP for normal terrain" do 
			setup_lord_user

			@lord_character.action_points = 4
			@lord_character.save!

			hex = Hex.in_game(@lord.game).around(@lord_army.location).not_terrain('Sea').first
			if hex.difficult? || hex.impassable?
				hex.terrain = "Plains"
				hex.save!
			end
			direction = @lord_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			post_action(@lord_army, 'MoveArmy', {direction: direction})
			test_response(200, true)

			@lord_character.reload
			expect(@lord_character.action_points).to eq(0)
		end

		it "successfully uses up right AP for difficult terrain" do 
			setup_lord_user

			@lord_character.action_points = 8
			@lord_character.save!

			hex = Hex.in_game(@lord.game).around(@lord_army.location).not_terrain('Sea').first
			hex.terrain = "Forest"
			hex.save!
			direction = @lord_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			post_action(@lord_army, 'MoveArmy', {direction: direction})
			test_response(200, true)

			@lord_character.reload
			expect(@lord_character.action_points).to eq(0)
		end

		it "fails if not all parameters" do 
			setup_lord_user

			post_action(@lord_army, 'MoveArmy', {})
			test_response(422)
		end

		it "successfully ends any siege the army is conductiing" do 
			setup_two_users_at_same_location

			@user2_army.besiege!(@user1_settlement)
			expect(@user1_settlement.under_siege).to eq(true)
			expect(@user2_army.sieging).to eq(@user1_settlement)

			hex = Hex.in_game(@user2.game).around(@user2_army.location).not_terrain('Sea').first
			if hex.difficult? || hex.impassable?
				hex.terrain = "Plains"
				hex.save!
			end
			direction = @user2_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			post_action(@user2_army, 'MoveArmy', {direction: direction})
			test_response(200, true)

			@user2_army.reload
			@user1_settlement.reload
			expect(@user1_settlement.under_siege).to eq(false)
			expect(@user2_army.sieging).to be_nil
		end

		it "successfully cancels any challenge issued by characters in the army" do 
			setup_two_users_at_same_location
			challenge = setup_challenge

			hex = Hex.in_game(@user1.game).around(@user1_army.location).not_terrain('Sea').first
			if hex.difficult? || hex.impassable?
				hex.terrain = "Plains"
				hex.save!
			end
			direction = @user1_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			post_action(@user1_army, 'MoveArmy', {direction: direction})
			test_response(200, true)

			@user1_character.reload
			@user2_character.reload
			expect(@user1_character.challenges.count).to eq(0)
			expect(@user2_character.challenges.count).to eq(0)
		end

		it "successfully rejects any challenge made to characters in the army" do 
			setup_two_users_at_same_location
			challenge = setup_challenge

			hex = Hex.in_game(@user2.game).around(@user2_army.location).not_terrain('Sea').first
			if hex.difficult? || hex.impassable?
				hex.terrain = "Plains"
				hex.save!
			end
			direction = @user2_army.location.direction_to(hex)
			expect(direction).to_not be_nil

			post_action(@user2_army, 'MoveArmy', {direction: direction})
			test_response(200, true)

			@user1_character.reload
			@user2_character.reload
			expect(@user1_character.challenges.count).to eq(0)
			expect(@user2_character.challenges.count).to eq(0)
		end
	end

	describe "Permit Member" do
		it "successfully permits member to publish news" do
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user1_character, 'PermitMember', {character_id: @user2_character.id, news: true})
			test_response(200)

			alliance.reload
			expect(alliance.can_publish_news?(@user2_character)).to eq(true)
		end

		it "successfully permits member to invite members" do 
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user1_character, 'PermitMember', {character_id: @user2_character.id, invite: true})
			test_response(200)

			alliance.reload
			expect(alliance.can_invite?(@user2_character)).to eq(true)
		end

		it "successfully permits nenber to kick members" do 
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user1_character, 'PermitMember', {character_id: @user2_character.id, kick: true})
			test_response(200)

			alliance.reload
			expect(alliance.can_kick?(@user2_character)).to eq(true)
		end

		it "fails if not alliance leader" do 
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user2_character, 'PermitMember', {character_id: @user1_character.id, news: true})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user1_character, 'PermitMember', {})
			test_response(422)
		end
	end

	describe "Produce Item" do
		it "successfully produces weapon" do 
			setup_lord_user

			give_items(@lord_settlement, 'Wood', 1)
			item = Item.named("Club").first

			post_action(@lord_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(200, true)

			@lord_settlement.reload
			expect(@lord_settlement.item_count(Item.named('Wood').first)).to eq(0)
			expect(@lord_settlement.item_count(item)).to eq(1)
		end

		it "successfully produces armour" do 
			setup_lord_user

			give_items(@lord_settlement, 'Hide', 1)
			item = Item.named("Leather").first

			#raise "LEATHER HIDE #{item.hide} - AVAILABLE: #{@lord_settlement.item_count('Hide')}"

			post_action(@lord_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(200, true)

			@lord_settlement.reload
			expect(@lord_settlement.item_count(Item.named('Hide').first)).to eq(0)
			expect(@lord_settlement.item_count(item)).to eq(1)
		end

		it "successfully produces vehicles" do 
			setup_lord_user

			give_items(@lord_settlement, 'Wood', 50)
			item = Item.named("Wagon").first

			post_action(@lord_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(200, true)

			@lord_settlement.reload
			expect(@lord_settlement.item_count(Item.named('Wood').first)).to eq(0)
			expect(@lord_settlement.item_count(item)).to eq(1)
		end

		it "successfully produces siege equipment" do 
			setup_lord_user

			give_items(@lord_settlement, 'Wood', 10)
			item = Item.named("Battering Ram").first

			post_action(@lord_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(200, true)

			@lord_settlement.reload
			expect(@lord_settlement.item_count(Item.named('Wood').first)).to eq(0)
			expect(@lord_settlement.item_count(item)).to eq(1)
		end

		it "successfully produces trade goods" do 
			setup_hero_user

			give_items(@hero_settlement, 'Wood', 2)
			item = Item.named("Luxuries").first

			post_action(@hero_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(200, true)

			@hero_settlement.reload
			expect(@hero_settlement.item_count(Item.named('Wood').first)).to eq(0)
			expect(@hero_settlement.item_count(item)).to eq(1)
		end

		it "fails if not enough raw materials" do 
			setup_lord_user

			item = Item.named("Club").first

			post_action(@lord_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(422)
		end

		it "fails if producing trade goods but not a guild" do 
			setup_lord_user

			give_items(@lord_settlement, 'Wood', 2)
			item = Item.named("Luxuries").first

			post_action(@lord_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(422)
		end

		it "fails if producing armour but not a guild or city" do 
			setup_dragon_user

			give_items(@dragon_settlement, 'Hide', 1)
			item = Item.named("Leather").first

			post_action(@dragon_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(422)
		end

		it "fails if producing weapon but not a guild or city" do 
			setup_dragon_user

			give_items(@dragon_settlement, 'Wood', 1)
			item = Item.named("Club").first

			post_action(@dragon_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(422)
		end

		it "fails if producing vehicles but not a guild or city" do 
			setup_dragon_user

			give_items(@dragon_settlement, 'Wood', 50)
			item = Item.named("Wagon").first

			post_action(@dragon_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(422)
		end

		it "fails if producing siege equipment but not a guild or city" do 
			setup_dragon_user

			give_items(@dragon_settlement, 'Wood', 10)
			item = Item.named("Battering Ram").first

			post_action(@dragon_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(422)
		end

		it "fails if producing magical items" do 
			setup_lord_user

			item = Item.create_magic_item!(:armour, :strength_rating, 1)

			post_action(@lord_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(422)
		end

		it "fails if producing anything with a race" do 
			setup_lord_user

			item = Item.of_race('Human').first

			post_action(@lord_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(422)
		end

		it "fails if producing resources" do 
			setup_lord_user

			item = Item.named('Wood').first

			post_action(@lord_settlement, 'ProduceItem', {item_id: item.id, quantity: 1})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_lord_user

			give_items(@lord_settlement, 'Wood', 10)
			item = Item.named("Battering Ram").first

			post_action(@lord_settlement, 'ProduceItem', {})
			test_response(422)
		end

	end

	describe "Publish News" do
		it "successfully publishes news" do 
			setup_two_users_at_same_location
			alliance = ally_users

			alliance.give_publish_news_rights!(@user2_character)

			post_action(@user2_character, 'PublishNews', {text: 'This is the news'})
			test_response(200, true)

			@user2_character.reload

			expect(Rumour.in_game(@user2_character.game).at_loc(@user2_character.location).count).to eq(1)
		end

		it "fails if not an alliance member with publish rights" do 
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user2_character, 'PublishNews', {text: 'This is the news'})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location
			alliance = ally_users

			alliance.give_publish_news_rights!(@user2_character)

			post_action(@user2_character, 'PublishNews', {})
			test_response(422)
		end
	end

	describe "Rally Troops" do
		it "successfully rallies troops" do 
			setup_lord_user

			unit = @lord_army.units.first
			unit.health = 75
			unit.save!

			@lord_character.renown = 1
			@lord_character.save!

			post_action(@lord_character, 'RallyTroops', {unit_id: unit.id})
			test_response(200)

			unit.reload
			@lord_character.reload

			expect(unit.health).to eq(100)
			expect(@lord_character.renown).to eq(0)
		end

		it "fails if not a character" do 
			setup_lord_user

			unit = @lord_army.units.first
			unit.health = 75
			unit.save!

			@lord_character.renown = 1
			@lord_character.save!

			post_action(@lord_army, 'RallyTroops', {unit_id: unit.id})
			test_response(422)
		end

		it "fails if not enough renown" do 
			setup_lord_user

			unit = @lord_army.units.first
			unit.health = 75
			unit.save!

			post_action(@lord_character, 'RallyTroops', {unit_id: unit.id})
			test_response(422)
		end

		it "fails if target isn't a unit" do 
			setup_lord_user

			unit = @lord_army.units.first
			unit.health = 75
			unit.save!

			@lord_character.renown = 1
			@lord_character.save!

			post_action(@lord_character, 'RallyTroops', {unit_id: @lord_army.id})
			test_response(422)
		end

		it "fails if target unit's army isn't in the same location" do
			setup_lord_user

			army = setup_army(@lord_character)
			move_to_random_location(army)
			army.save!

			unit = setup_unit(army, Item.named('Orc').first)
			unit.health = 75
			unit.save!

			@lord_character.renown = 1
			@lord_character.save!

			post_action(@lord_character, 'RallyTroops', {unit_id: unit.id})
			test_response(422)
		end

		it "fails if target unit is at maximum health" do 
			setup_lord_user

			unit = @lord_army.units.first
			unit.health = 100
			unit.save!

			@lord_character.renown = 1
			@lord_character.save!

			post_action(@lord_character, 'RallyTroops', {unit_id: unit.id})
			test_response(422)
		end
	end

	describe "Raze Settlement" do
		it "successfully reduces defence rating by 1" do 
			setup_two_users_at_same_location
			@user1_army.destroy

			@user1_settlement.defence_rating = 2
			@user1_settlement.save!

			@user2_army.units.each {|u| u.destroy unless @user2_army.units.first == u}
			@user2_army.reload
			unit = @user2_army.units.first
			unit.strength_rating = 10
			unit.save!

			post_action(@user2_army, 'RazeSettlement', {})
			test_response(200)

			@user1_settlement.reload
			expect(@user1_settlement.defence_rating).to eq(1)
		end

		it "successfully destroyed undefended settlement" do 
			setup_two_users_at_same_location
			@user1_army.destroy
			@user1_settlement.defence_rating = 1
			@user1_settlement.save!

			post_action(@user2_army, 'RazeSettlement', {})
			test_response(200, true)

			@user1_character.reload

			expect(Settlement.owned_by(@user1_character).count).to eq(0)
		end

		it "fails if not an army" do 
			setup_two_users_at_same_location
			@user1_army.destroy

			post_action(@user2_character, 'RazeSettlement', {})
			test_response(422)
		end

		it "fails if there is an army friendly to the settlement guarding this location" do 
			setup_two_users_at_same_location

			@user1_army.guarding = true
			@user1_army.save!
			
			post_action(@user2_army, 'RazeSettlement', {})
			test_response(422)
		end

		it "fails if army not at settlement location" do 
			setup_two_users_at_same_location
			@user1_army.destroy
			move_to_random_location(@user2_army)
			@user2_army.save!

			post_action(@user2_army, 'RazeSettlement', {})
			test_response(422)
		end

		it "fails if settlement is friendly" do 
			setup_two_users_at_same_location
			@user1_army.destroy
			ally_users

			post_action(@user2_army, 'RazeSettlement', {})
			test_response(422)
		end

		it "fails if settlement is neutral" do 
			setup_lord_user

			neutral = Settlement.neutral.first
			@lord_army.location = neutral.location
			@lord_army.save!

			post_action(@lord_army, 'RazeSettlement', {})
			test_response(422)
		end
	end

	describe "Scout Hex" do
		it "successfully scouts a hex" do 
			pending "scouting engine"
			setup_two_users_at_same_location

			hex = Hex.in_game(@user2.game).around(@user2_army.location).not_terrain('Sea').first
			direction = @user2_army.location.direction_to(hex)

			post_action(@user2_army, 'ScoutHex', {hex: hex.location.id, unit_id: @user2_army.units.first.id })
			test_response(200)

			expect(@user2_army.scout_reports.count).to eq(1)
		end

		it "fails if not an army" do 
			setup_two_users_at_same_location

			hex = Hex.in_game(@user2.game).around(@user2_army.location).not_terrain('Sea').first
			direction = @user2_army.location.direction_to(hex)

			post_action(@user2_character, 'ScoutHex', {hex: hex.location.id, unit_id: @user2_army.units.first.id })
			test_response(422)
		end

		it "fails if unit is not part of army" do 
			setup_two_users_at_same_location

			hex = Hex.in_game(@user2.game).around(@user2_army.location).not_terrain('Sea').first
			direction = @user2_army.location.direction_to(hex)

			post_action(@user2_army, 'ScoutHex', {hex: hex.location.id, unit_id: @user1_army.units.first.id })
			test_response(422)
		end

		it "fails if target hex is not adjacent to location" do 
			setup_two_users_at_same_location

			hex = Hex.in_game(@user1.game).around(@user1_army.location).not_terrain('Sea').first
			direction = @user1_army.location.direction_to(hex)

			move_to_random_location(@user2_army)
			@user2_army.save!

			post_action(@user2_army, 'ScoutHex', {hex: hex.location.id, unit_id: @user2_army.units.first.id })
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location

			hex = Hex.in_game(@user2.game).around(@user2_army.location).not_terrain('Sea').first
			direction = @user2_army.location.direction_to(hex)

			post_action(@user2_army, 'ScoutHex', {})
			test_response(422)
		end
	end

	describe "Sell Item" do
		it "successfully puts a sell order" do 
			setup_hero_user
			item = Item.named('Wood').first

			give_items(@hero_settlement, 'Wood', 1000)

			post_action(@hero_settlement,'SellItem',{item_id: item.id, quantity: 1000, price: 1})
			test_response(200)

			expect(Sell.where(position: @hero_settlement, item: item).count).to eq(1)
		end

		it "fails if not all parameters" do 
			setup_hero_user
			item = Item.named('Wood').first

			give_items(@hero_settlement, 'Wood', 1000)

			post_action(@hero_settlement,'SellItem',{})
			test_response(422)
		end
	end

	describe "Spend Experience" do
		it "successfully spends experience to raise an attribute" do 
			setup_hero_user

			@hero_character.experience_points = 25
			@hero_character.strength_rating = 5
			@hero_character.save!

			post_action(@hero_character, 'SpendExperience', {attribute: 'strength_rating'})
			test_response(200, true)

			@hero_character.reload
			expect(@hero_character.experience_points).to eq(0)
			expect(@hero_character.strength_rating).to eq(6)
		end

		it "fails if not a character" do 
			setup_hero_user

			@hero_character.experience_points = 25
			@hero_character.strength_rating = 5
			@hero_character.save!

			post_action(@hero_army, 'SpendExperience', {attribute: 'strength_rating'})
			test_response(422)
		end

		it "fails if insufficient experience" do 
			setup_hero_user

			@hero_character.experience_points = 24
			@hero_character.strength_rating = 5
			@hero_character.save!

			post_action(@hero_character, 'SpendExperience', {attribute: 'strength_rating'})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_hero_user

			@hero_character.experience_points = 25
			@hero_character.strength_rating = 5
			@hero_character.save!

			post_action(@hero_character, 'SpendExperience', {})
			test_response(422)
		end
	end

	describe "Subvert City" do
		it "successfully subverts a city" do 
			setup_two_users_at_same_location

			@user1_settlement.population_loyalty = 1
			@user1_settlement.save!
			@user2_character.cunning_rating = 7
			@user2_character.save!

			post_action(@user2_character, 'SubvertCity',{})
			test_response(200)

			@user1_settlement.reload
			expect(@user1_settlement.owner).to eq(@user2_character)
		end

		it "fails if not a character" do 
			setup_two_users_at_same_location

			@user1_settlement.population_loyalty = 1
			@user1_settlement.save!
			@user2_character.cunning_rating = 7
			@user2_character.save!

			post_action(@user2_army, 'SubvertCity',{})
			test_response(422)
		end

		it "fails if character cunning too low" do 
			setup_two_users_at_same_location

			@user1_settlement.population_loyalty = 50
			@user1_settlement.save!
			@user2_character.cunning_rating = 5
			@user2_character.save!

			post_action(@user2_character, 'SubvertCity',{})
			test_response(200)

			@user1_settlement.reload
			expect(@user1_settlement.owner).to_not eq(@user2_character)
		end

		it "fails if no city in location" do 
			setup_two_users_at_same_location

			@user1_settlement.population_loyalty = 1
			@user1_settlement.save!
			@user2_character.cunning_rating = 7
			@user2_character.save!

			move_to_random_location(@user2_army)
			@user2_army.save!

			post_action(@user2_character, 'SubvertCity',{})
			test_response(422)
		end

		it "fails if target is friendly" do 
			setup_two_users_at_same_location
			ally_users

			@user1_settlement.population_loyalty = 1
			@user1_settlement.save!
			@user2_character.cunning_rating = 7
			@user2_character.save!

			post_action(@user2_character, 'SubvertCity',{})
			test_response(422)
		end

		it "fails if target is neutral" do 
			setup_lord_user

			neutral = Settlement.of_type('City').neutral.first
			@lord_army.location = neutral.location 
			@lord_army.save!

			neutral.population_loyalty = 1
			neutral.save!
			@lord_character.cunning_rating = 7
			@lord_character.save!

			post_action(@lord_character, 'SubvertCity',{})
			test_response(422)
		end
	end

	describe "Tax City" do
		it "successfully taxes city population" do
			setup_lord_user

			@lord_character.gold = 0
			@lord_character.save!
			@lord_settlement.population_size = 10000
			@lord_settlement.population_loyalty = 100
			@lord_settlement.save!

			post_action(@lord_settlement, 'TaxCity', {})
			test_response(200)

			@lord_character.reload
			@lord_settlement.reload
			expect(@lord_character.gold).to_not eq(0)
			expect(@lord_settlement.population_loyalty).to eq(100 - Settlement::LOYALTY_LOSS_FOR_TAXATION)
		end

		it "fails if not a city" do
			setup_necromancer_user

			post_action(@necromancer_settlement, 'TaxCity', {})
			test_response(422)
		end

		it "fails if loyalty too low" do 
			setup_lord_user

			@lord_settlement.population_size = 10000
			@lord_settlement.population_loyalty = 4
			@lord_settlement.save!

			post_action(@lord_settlement, 'TaxCity', {})
			test_response(422)
		end

		it "fails if taxed this year" do 
			setup_lord_user

			@lord_character.gold = 0
			@lord_character.save!
			@lord_settlement.population_size = 10000
			@lord_settlement.population_loyalty = 100
			@lord_settlement.save!

			post_action(@lord_settlement, 'TaxCity', {})
			test_response(200)

			post_action(@lord_settlement, 'TaxCity', {})
			test_response(422)
		end
	end

	describe "Train Unit" do
		it "successfully trains a unit" do 
			setup_lord_user
			setup_guild(@lord_settlement)

			@lord_character.gold = 500
			@lord_character.save!

			unit = @lord_army.units.first

			post_action(@lord_army, 'TrainUnit', {unit_id: unit.id, training: 'Archery'})
			test_response(200, true)

			unit.reload
			@lord_character.reload
			expect(unit.training).to eq('Archery')
			expect(@lord_character.gold).to_not eq(500)
		end

		it "fails if not an army" do 
			setup_lord_user
			setup_guild(@lord_settlement)

			@lord_character.gold = 500
			@lord_character.save!

			unit = @lord_army.units.first

			post_action(@lord_character, 'TrainUnit', {unit_id: unit.id, training: 'Archery'})
			test_response(422)
		end

		it "fails if unit is undead" do 
			setup_necromancer_user
			setup_lord_user
			setup_guild(@lord_settlement)
			ally_users(@lord_character, @necromancer_character)
			@necromancer_army.location = @lord_settlement.location
			@necromancer_army.save!

			unit = setup_unit(@necromancer_army, Item.named('Skeleton').first)
			post_action(@necromancer_army, 'TrainUnit', {unit_id: unit.id, training: 'Archery'})
			test_response(422)
		end

		it "fails if unit is elemental" do 
			setup_dragon_user
			setup_lord_user
			setup_guild(@lord_settlement)
			ally_users(@lord_character, @dragon_character)
			@dragon_army.location = @lord_settlement.location
			@dragon_army.save!

			unit = setup_unit(@dragon_army, Item.named('Imp').first)
			post_action(@dragon_army, 'TrainUnit', {unit_id: unit.id, training: 'Archery'})
			test_response(422)
		end

		it "fails if not in same location as a neutral or friendly guild" do 
			setup_lord_user
			@lord_settlement.guild.destroy if @lord_settlement.guild

			@lord_character.gold = 500
			@lord_character.save!

			unit = @lord_army.units.first

			post_action(@lord_army, 'TrainUnit', {unit_id: unit.id, training: 'Archery'})
			test_response(422)
		end

		it "fails if insufficient gold" do 
			setup_lord_user
			setup_guild(@lord_settlement)

			@lord_character.gold = 0
			@lord_character.save!

			unit = @lord_army.units.first

			post_action(@lord_army, 'TrainUnit', {unit_id: unit.id, training: 'Archery'})
			test_response(422)
		end

		it "charges more for stupid races" do 
			setup_lord_user
			setup_guild(@lord_settlement)

			@lord_character.gold = 500
			@lord_character.save!

			unit = setup_unit(@lord_army, Item.named('Ogre').first)

			post_action(@lord_army, 'TrainUnit', {unit_id: unit.id, training: 'Archery'})
			test_response(200, true)

			unit.reload
			@lord_character.reload
			expect(unit.training).to eq('Archery')
			expect(@lord_character.gold).to eq(200)
		end

		it "charges less for smart races" do 
			setup_lord_user
			setup_guild(@lord_settlement)

			@lord_character.gold = 500
			@lord_character.save!

			unit = setup_unit(@lord_army, Item.named('Elf').first)

			post_action(@lord_army, 'TrainUnit', {unit_id: unit.id, training: 'Archery'})
			test_response(200, true)

			unit.reload
			@lord_character.reload
			expect(unit.training).to eq('Archery')
			expect(@lord_character.gold).to eq(450)
		end

		it "gives gold to guild owner" do 
			setup_lord_user
			setup_hero_user
			ally_users(@lord_character, @hero_character)

			setup_guild(@lord_settlement, @hero_user)

			@lord_character.gold = 500
			@lord_character.save!
			@hero_character.gold = 0
			@hero_character.save!

			unit = setup_unit(@lord_army, Item.named('Ogre').first)

			post_action(@lord_army, 'TrainUnit', {unit_id: unit.id, training: 'Archery'})
			test_response(200, true)

			@hero_character.reload
			expect(@hero_character.gold).to eq(30)
		end

		it "fails if not all parameters" do 
			setup_lord_user
			setup_guild(@lord_settlement)

			@lord_character.gold = 500
			@lord_character.save!

			unit = @lord_army.units.first

			post_action(@lord_army, 'TrainUnit', {})
			test_response(422)
		end
	end

	describe "Transfer Gold" do
		it "successfully transfers gold" do 
			setup_two_users_at_same_location

			@user1_character.gold = 100
			@user2_character.gold = 0
			@user1_character.save!
			@user2_character.save!

			post_action(@user1_character, 'TransferGold', {character_id: @user2_character.id, amount: 100})
			test_response(200)

			@user1_character.reload
			@user2_character.reload
			expect(@user1_character.gold).to eq(0)
			expect(@user2_character.gold).to eq(100)
		end

		it "fails if insufficient gold" do 
			setup_two_users_at_same_location

			@user1_character.gold = 100
			@user2_character.gold = 0
			@user1_character.save!
			@user2_character.save!

			post_action(@user1_character, 'TransferGold', {character_id: @user2_character.id, amount: 101})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location

			@user1_character.gold = 100
			@user2_character.gold = 0
			@user1_character.save!
			@user2_character.save!

			post_action(@user1_character, 'TransferGold', {})
			test_response(422)
		end
	end

	describe "Transfer Item" do
		it "successfully transfers items" do 
			setup_lord_user

			give_items(@lord_settlement, 'Club', 100)
			item = Item.named('Club').first

			post_action(@lord_settlement, 'TransferItem', {target: @lord_army.id, item_id: item.id, quantity: 100})
			test_response(200)

			@lord_settlement.reload
			@lord_army.reload
			expect(@lord_settlement.item_count(item)).to eq(0)
			expect(@lord_army.item_count(item)).to eq(100)
		end

		it "fails if not in same location" do 
			setup_lord_user

			give_items(@lord_settlement, 'Club', 100)
			item = Item.named('Club').first

			move_to_random_location(@lord_army)
			@lord_army.save!

			post_action(@lord_settlement, 'TransferItem', {target: @lord_army.id, item_id: item.id, quantity: 100})
			test_response(422)
		end

		it "fails if transferring non-magical items to a character" do
			setup_lord_user

			give_items(@lord_settlement, 'Club', 100)
			item = Item.named('Club').first

			post_action(@lord_settlement, 'TransferItem', {target: @lord_character.id, item_id: item.id, quantity: 100})
			test_response(422)
		end

		it "successfully adjusts army movement type" do 
			setup_lord_user

			expect(@lord_army.movement_land?).to eq(true)

			give_items(@lord_settlement, 'Club', 1000)
			item = Item.named('Club').first

			post_action(@lord_settlement, 'TransferItem', {target: @lord_army.id, item_id: item.id, quantity: 1000})
			test_response(200)

			@lord_army.reload
			expect(@lord_army.immobile?).to eq(true)
		end

		it "fails if not all parameters" do 
			setup_lord_user

			give_items(@lord_settlement, 'Club', 100)
			item = Item.named('Club').first

			post_action(@lord_settlement, 'TransferItem', {})
			test_response(422)
		end
	end

	describe "Transfer Leadership" do
		it "successfully transfers leadership" do 
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user1_character, 'TransferLeadership', {character_id: @user2_character.id })
			test_response(200)

			alliance.reload
			expect(alliance.leader?(@user1_character)).to eq(false)
			expect(alliance.leader?(@user2_character)).to eq(true)
		end

		it "fails if not alliance leader" do
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user2_character, 'TransferLeadership', {character_id: @user1_character.id })
			test_response(422)
		end

		it "fails if target isn't a member of the alliance" do 
			setup_two_users_at_same_location
			alliance = setup_alliance

			post_action(@user1_character, 'TransferLeadership', {character_id: @user2_character.id })
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location
			alliance = ally_users

			post_action(@user1_character, 'TransferLeadership', {})
			test_response(422)
		end
	end

	describe "Transfer Position" do
		it "successfully transfers position" do 
			setup_two_users_at_same_location

			post_action(@user1_character, 'TransferPosition', {position_id: @user1_army.id, character_id: @user2_character.id })
			test_response(200)

			@user1_army.reload
			expect(@user1_army.owner).to eq(@user2_character)
		end

		it "fails if character" do 
			setup_two_users_at_same_location

			post_action(@user1_character, 'TransferPosition', {position_id: @user1_character.id, character_id: @user2_character.id })
			test_response(422)
		end

		it "fails if target isn't a character" do 
			setup_two_users_at_same_location

			post_action(@user1_character, 'TransferPosition', {position_id: @user1_army.id, character_id: @user2_army.id })
			test_response(422)
		end

		it "fails if settlement type doesn't match target character" do 
			setup_two_users_at_same_location('Lord', 'Hero')

			post_action(@user1_character, 'TransferPosition', {position_id: @user1_settlement.id, character_id: @user2_character.id })
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location

			post_action(@user1_army, 'TransferPosition', { })
			test_response(422)
		end
	end

	describe "Transfer Unit" do
		it "successfully transfers a unit" do 
			setup_two_users_at_same_location

			unit = @user2_army.units.last

			post_action(@user2_army, 'TransferUnit', {unit_id: unit.id, army_id: @user1_army.id})
			test_response(200)

			unit.reload
			expect(unit.army).to eq(@user1_army)
		end

		it "fails if not an army" do 
			setup_two_users_at_same_location

			unit = @user2_army.units.last

			post_action(@user2_character, 'TransferUnit', {unit_id: unit.id, army_id: @user1_army.id})
			test_response(422)
		end

		it "fails if target isn't an army" do 
			setup_two_users_at_same_location

			unit = @user2_army.units.last

			post_action(@user2_army, 'TransferUnit', {unit_id: unit.id, army_id: @user1_settlement.id})
			test_response(422)
		end

		it "fails if target isn't at same location" do 
			setup_two_users_at_same_location

			move_to_random_location(@user2_army)
			@user2_army.save!

			unit = @user2_army.units.last

			post_action(@user2_army, 'TransferUnit', {unit_id: unit.id, army_id: @user1_army.id})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_two_users_at_same_location

			unit = @user2_army.units.last

			post_action(@user2_army, 'TransferUnit', {})
			test_response(422)
		end
	end

	describe "Unit Tactics" do
		it "successfully changes a unit's tactics" do 
			setup_lord_user

			unit = @lord_army.units.last
			unit.training = 'Infiltration'
			unit.save!

			post_action(@lord_army, 'UnitTactics', {unit_id: unit.id, tactic: 'Ambush'})
			test_response(200, true)

			unit.reload
			expect(unit.tactic).to eq('Ambush')
		end

		it "fails if not an army" do 
			setup_lord_user

			unit = @lord_army.units.last
			unit.training = 'Infiltration'
			unit.save!

			post_action(@lord_settlement, 'UnitTactics', {unit_id: unit.id, tactic: 'Ambush'})
			test_response(422)
		end

		it "fails if target unit isn't part of the army" do
			setup_two_users_at_same_location

			unit = @user1_army.units.last
			unit.training = 'Infiltration'
			unit.save!

			post_action(@user2_army, 'UnitTactics', {unit_id: unit.id, tactic: 'Ambush'})
			test_response(422)
		end

		it "fails if target unit lacks training for the tactic" do 
			setup_lord_user

			unit = @lord_army.units.last
			
			post_action(@lord_army, 'UnitTactics', {unit_id: unit.id, tactic: 'Ambush'})
			test_response(422)
		end

		it "fails if not all parameters" do 
			setup_lord_user

			unit = @lord_army.units.last
			unit.training = 'Infiltration'
			unit.save!

			post_action(@lord_army, 'UnitTactics', {})
			test_response(422)
		end
	end
end
