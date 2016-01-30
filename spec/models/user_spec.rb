require 'rails_helper'

RSpec.describe User, type: :model do
	include PositionFactory

	before(:each) do
		Game.first.update_attributes!(year: 10)
		@game = Game.first
  	end

  	after(:each) do
  		clear_up_positions
  		Game.first.update_attributes!(year: 1)
  	end

	describe "Create User" do
		it "successfully create a user" do 
			@user = setup_hero_user(false)
			expect(@user).to be_persisted
		end

		it "should have an auth token" do
			@user = setup_hero_user(false)
			expect(@user.auth_token).to_not be_blank
		end
	end

	describe "Update User" do 
		it "successfully updates a user" do 
			@user = setup_hero_user
			@user.update_attributes!(name: 'Updated')
			expect(@user.name).to eq('Updated')
		end
	end

	describe "Confirm User" do 
		it "successfully confirms a user" do 
			@user = setup_hero_user(false)
			@user.update_attributes!(confirmed: true)
			expect(@user.confirmed).to eq(true)
		end
	end

	describe "Setup User" do 
		it "successfully create a character" do 
			setup_hero_user
			expect(@hero_character).to_not be_nil
		end

		it "successfully create guild for heroes" do 
			setup_hero_user
			settlement = Settlement.owned_by(@hero_character).first
			expect(settlement).to_not be_nil
			expect(settlement.settlement_type).to eq('Guild')
		end

		it "successfully create city for lord" do 
			setup_lord_user
			settlement = Settlement.owned_by(@lord_character).first
			expect(settlement).to_not be_nil
			expect(settlement.settlement_type).to eq('City')
		end

		it "successfully create tower for necromancers" do 
			setup_necromancer_user
			settlement = Settlement.owned_by(@necromancer_character).first
			expect(settlement).to_not be_nil
			expect(settlement.settlement_type).to eq('Tower')
		end

		it "successfully create lair for dragons" do 
			setup_dragon_user
			settlement = Settlement.owned_by(@dragon_character).first
			expect(settlement).to_not be_nil
			expect(settlement.settlement_type).to eq('Lair')
		end

		it "should create 2 positions" do 
			setup_hero_user
			expect(@hero_character.positions.count).to eq(2)
		end

		it "should create army and character unit" do 
			setup_hero_user
			expect(@hero_character.army).to_not be_nil
			expect(@hero_character.unit).to_not be_nil
		end

		it "should create 1 unit per year game has been going for a lord" do 
			setup_lord_user
			army = Army.owned_by(@lord_character).first
			expect(army.units.count).to eq(@game.year + 1)
		end

		it "should create 1 unit per year game has been going for a necromancer" do 
			setup_necromancer_user
			army = Army.owned_by(@necromancer_character).first
			expect(army.units.count).to eq(@game.year + 1)
		end

		it "should create 1 unit per year game has been going for a dragon" do 
			setup_dragon_user
			army = Army.owned_by(@dragon_character).first
			expect(army.units.count).to eq(@game.year + 1)
		end

		it "should give 100 + 100 gold per year game has been going" do 
			setup_hero_user
			expect(@hero_character.gold).to eq(100 + (@game.year * 100))
		end
	end

	describe "Delete User" do 
		it "successfully deletes a user" do 
			@user = setup_hero_user
			@user.destroy
			expect(@user).to_not be_persisted
		end
	end
end
