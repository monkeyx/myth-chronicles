require 'rails_helper'

RSpec.describe Character, type: :model do
	include PositionFactory

	before(:each) do 
		@game = Game.first
	end

	after(:each) do
  		clear_up_positions
  	end

	describe "character attributes" do 
		it "successfully sets up hero" do 
			setup_hero_user
			expect(@hero_character.strength_rating).to eq(7)
			expect(@hero_character.armour_rating).to eq(7)
			expect(@hero_character.leadership_rating).to eq(5)
			expect(@hero_character.cunning_rating).to eq(5)
			expect(@hero_character.craft_rating).to eq(5)
			expect(@hero_character.speed_rating).to eq(5)
		end

		it "successfully sets up lord" do 
			setup_lord_user
			expect(@lord_character.strength_rating).to eq(5)
			expect(@lord_character.armour_rating).to eq(5)
			expect(@lord_character.leadership_rating).to eq(7)
			expect(@lord_character.cunning_rating).to eq(7)
			expect(@lord_character.craft_rating).to eq(3)
			expect(@lord_character.speed_rating).to eq(3)
		end

		it "successfully sets up necromancer" do 
			setup_necromancer_user
			expect(@necromancer_character.strength_rating).to eq(3)
			expect(@necromancer_character.armour_rating).to eq(3)
			expect(@necromancer_character.leadership_rating).to eq(5)
			expect(@necromancer_character.cunning_rating).to eq(5)
			expect(@necromancer_character.craft_rating).to eq(10)
			expect(@necromancer_character.speed_rating).to eq(3)
		end

		it "successfully sets up dragon" do 
			setup_dragon_user
			expect(@dragon_character.strength_rating).to eq(10)
			expect(@dragon_character.armour_rating).to eq(10)
			expect(@dragon_character.leadership_rating).to eq(3)
			expect(@dragon_character.cunning_rating).to eq(3)
			expect(@dragon_character.craft_rating).to eq(5)
			expect(@dragon_character.speed_rating).to eq(5)
		end
	end
end
