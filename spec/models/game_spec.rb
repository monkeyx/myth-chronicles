require 'rails_helper'

RSpec.describe Game, type: :model do
	include PositionFactory

	before(:each) do 
		@game = Game.first
	end

	after(:each) do
  		clear_up_positions
  	end

	describe "Cycle Game" do 
		it "finds game due to update" do 
			@game.last_cycle = Time.now - 1.day
			@game.cycle_frequency = 1
			@game.save!

			expect(Game.due_cycle.count).to eq(1)
		end

		it "doesn't find game not due for an update" do 
			@game.last_cycle = Time.now
			@game.save!

			expect(Game.due_cycle.count).to eq(0)
		end

		it "moves cycle forward" do 
			@game.game_time = Temporal::GameTime.new(1,1,1,1)
			@game.save!

			expect{
				@game.next_cycle!
			}.to change{@game.cycle}.from(1).to(2)

			@game.game_time = Temporal::GameTime.new(4,1,1,1)
			@game.save!

			expect{
				@game.next_cycle!
			}.to change{@game.season}.from(1).to(2)

			@game.game_time = Temporal::GameTime.new(4,4,1,1)
			@game.save!

			expect{
				@game.next_cycle!
			}.to change{@game.year}.from(1).to(2)

			@game.game_time = Temporal::GameTime.new(1,1,1,1)
			@game.save!
		end
	end

	describe "Cycle Game: Character Pool Generation" do

		it "generates mana points for characters" do 
			setup_necromancer_user

			@necromancer_character.mana_points = 0
			@necromancer_character.save!

			expect{
				CycleGame.character_pool_generation!(@game)
			}.to change{Character.where(id: @necromancer_character.id).first.mana_points}.from(0).to(6)

			setup_dragon_user

			@dragon_character.mana_points = 0
			@dragon_character.save!

			expect{
				CycleGame.character_pool_generation!(@game)
			}.to change{Character.where(id: @dragon_character.id).first.mana_points}.from(0).to(6)

			setup_hero_user

			@hero_character.mana_points = 0
			@hero_character.save!

			expect{
				CycleGame.character_pool_generation!(@game)
			}.to change{Character.where(id: @hero_character.id).first.mana_points}.from(0).to(4)
		end

		it "generates action points for characters" do 
			setup_hero_user

			@hero_character.action_points = 0
			@hero_character.save!

			expect{
				CycleGame.character_pool_generation!(@game)
			}.to change{Character.where(id: @hero_character.id).first.action_points}.from(0).to(16)
		end
	end

	describe "Cycle Game: Challenge Expiration" do 
		it "rejects challenges that have expired" do 
			setup_two_users_at_same_location
			challenge = setup_challenge

			@game.game_time = @game.game_time + 100
			@game.save!
			
			challenge.reload
			challenge.game_time = @game.game_time - (CharacterChallenge::CHALLENGE_EXPIRATION + 1)
			challenge.save!
			expect(challenge.expired?).to eq(true)

			expect{
				CycleGame.character_challenge_expiration!(@game)
			}.to change{CharacterChallenge.where(id: challenge.id).count}.from(1).to(0)

			@game.game_time = @game.game_time - 100
			@game.save
		end
	end

	describe "Cycle Game: Unit Health Regeneration" do

		it "regenerates health for units inside of friendly territory" do 
			setup_lord_user
			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			unit.health = 95
			unit.save!

			expect{
				CycleGame.unit_health_regeneration!(@game)
			}.to change{Unit.where(id: unit.id).first.health}.from(95).to(100)
		end

		it "regenerates health for units outside of friendly territory" do 
			setup_lord_user
			unit = setup_unit(@lord_army, @lord_settlement.recruitment_race_item)
			unit.health = 95
			unit.save!

			while @lord_army.in_friendly_territory? do 
				move_to_random_location(@lord_army)
			end

			expect{
				CycleGame.unit_health_regeneration!(@game)
			}.to change{Unit.where(id: unit.id).first.health}.from(95).to(96)
		end
	end

	describe "Cycle Game: Resource Generation" do

		it "generates wood for city" do 
			setup_lord_user

			hex = @lord_settlement.hex
			hex.terrain = 'Forest'
			hex.save!

			expect{
				CycleGame.city_resource_generation!(@game)
			}.to change{@lord_settlement.item_count('Wood')}.from(0).to(@lord_settlement.wood_produced)
		end

		it "generates hide for city" do 
			setup_lord_user

			hex = @lord_settlement.hex
			hex.terrain = 'Plains'
			hex.save!

			expect{
				CycleGame.city_resource_generation!(@game)
			}.to change{@lord_settlement.item_count('Hide')}.from(0).to(@lord_settlement.hides_produced)
		end

		it "generates iron for city" do 
			setup_lord_user

			hex = @lord_settlement.hex
			hex.terrain = 'Mountain'
			hex.save!

			expect{
				CycleGame.city_resource_generation!(@game)
			}.to change{@lord_settlement.item_count('Iron')}.from(0).to(@lord_settlement.iron_produced)
		end

		it "generates stone for city" do 
			setup_lord_user

			hex = @lord_settlement.hex
			hex.terrain = 'Hill'
			hex.save!

			expect{
				CycleGame.city_resource_generation!(@game)
			}.to change{@lord_settlement.item_count('Stone')}.from(0).to(@lord_settlement.stone_produced)
		end
	end

	describe "Cycle Game: Recruitment" do

		it "recruits humanoids for city" do 
			setup_lord_user

			expect(@lord_settlement.recruitment_rate).to_not be(0)

			expect{
				CycleGame.settlement_recruitment!(@game)
			}.to change{@lord_settlement.item_count(@lord_settlement.recruitment_race_item)}.from(0).to(@lord_settlement.recruitment_rate)
		end

		it "recruits undead for tower" do 
			setup_necromancer_user

			expect(@necromancer_settlement.recruitment_rate).to_not be(0)

			expect{
				CycleGame.settlement_recruitment!(@game)
			}.to change{@necromancer_settlement.item_count(@necromancer_settlement.recruitment_race_item)}.from(0).to(@necromancer_settlement.recruitment_rate)
		end

		it "recruits elemental for lair" do 
			setup_dragon_user

			expect(@dragon_settlement.recruitment_rate).to_not be(0)

			expect{
				CycleGame.settlement_recruitment!(@game)
			}.to change{@dragon_settlement.item_count(@dragon_settlement.recruitment_race_item)}.from(0).to(@dragon_settlement.recruitment_rate)
		end
	end

	describe "Cycle Game: Caravan Trade" do

		it "fulfills buy order" do 
			setup_two_users_at_same_location

			@user1_character.gold = 0
			@user1_character.save!
			@user2_character.gold = 1000000
			@user2_character.save!

			give_items(@user1_settlement, 'Wood', 100)
			item = Item.named('Wood').first

			Buy.delete_all
			Sell.delete_all

			buy = Buy.create!(position: @user2_settlement.position, item: item, quantity: 100, price: 100)
			sell = Sell.create!(position: @user1_settlement.position, item: item, quantity: 100, price: 1)

			buyer_cost = 100 * sell.actual_price(@user2_settlement)
			
			CycleGame.trade_caravans!(@game)

			@user1_settlement.reload
			@user2_settlement.reload
			@user1_character.reload
			@user2_character.reload

			expect(@user1_settlement.item_count(item)).to eq(0)
			expect(@user2_settlement.item_count(item)).to eq(100)
			expect(@user1_character.gold).to eq(100)
			expect(@user2_character.gold).to eq(1000000 - buyer_cost)
			expect(Buy.where(id: buy.id).count).to eq(0)
			expect(Sell.where(id: sell.id).count).to eq(0)
		end

		it "doesn't fulfill buy order if insufficient gold" do 
			setup_two_users_at_same_location

			@user1_character.gold = 0
			@user1_character.save!
			@user2_character.gold = 0
			@user2_character.save!

			give_items(@user1_settlement, 'Wood', 100)
			item = Item.named('Wood').first

			Buy.delete_all
			Sell.delete_all

			buy = Buy.create!(position: @user2_settlement.position, item: item, quantity: 100, price: 100)
			sell = Sell.create!(position: @user1_settlement.position, item: item, quantity: 100, price: 1)

			CycleGame.trade_caravans!(@game)

			@user1_settlement.reload
			@user2_settlement.reload
			@user1_character.reload
			@user2_character.reload

			expect(@user1_settlement.item_count(item)).to eq(100)
			expect(@user2_settlement.item_count(item)).to eq(0)
			expect(@user1_character.gold).to eq(0)
			expect(@user2_character.gold).to eq(0)
			expect(Buy.where(id: buy.id).count).to eq(1)
			expect(Sell.where(id: sell.id).count).to eq(1)
		end

		it "doesn't fulfill buy order if insufficient items at seller" do 
			setup_two_users_at_same_location

			@user1_character.gold = 0
			@user1_character.save!
			@user2_character.gold = 1000000
			@user2_character.save!

			item = Item.named('Wood').first

			Buy.delete_all
			Sell.delete_all

			buy = Buy.create!(position: @user2_settlement.position, item: item, quantity: 100, price: 100)
			sell = Sell.create!(position: @user1_settlement.position, item: item, quantity: 100, price: 1)

			CycleGame.trade_caravans!(@game)

			@user1_settlement.reload
			@user2_settlement.reload
			@user1_character.reload
			@user2_character.reload

			expect(@user1_settlement.item_count(item)).to eq(0)
			expect(@user2_settlement.item_count(item)).to eq(0)
			expect(@user1_character.gold).to eq(0)
			expect(@user2_character.gold).to eq(1000000)
			expect(Buy.where(id: buy.id).count).to eq(1)
			expect(Sell.where(id: sell.id).count).to eq(1)
		end
	end

	describe "Cycle Game: Rumours" do

		it "propagates rumours" do 
			setup_lord_user
			rumour = Rumour.publish_news!(@lord_character, 'Hello')

			expect{
				CycleGame.propagate_rumours!(@game)
			}.to change{Rumour.where(id: rumour.id).first.current_distance}.from(0).to(rumour.spread_rate)
		end

		it "expires rumours" do 
			setup_lord_user
			rumour = Rumour.publish_news!(@lord_character, 'Hello')
			
			@game.game_time = @game.game_time + 100
			@game.save!
			
			rumour.reload
			rumour.game_time =  @game.game_time - (Rumour::RUMOUR_EXPIRATION + 1)
			rumour.save!

			expect(rumour.expired?).to be(true)

			expect{
				CycleGame.propagate_rumours!(@game)
			}.to change{Rumour.where(id: rumour.id).count}.from(1).to(0)

			@game.game_time = @game.game_time - 100
			@game.save
		end
	end
end
