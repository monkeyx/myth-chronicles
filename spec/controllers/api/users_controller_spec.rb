require 'rails_helper'

RSpec.describe Api::UsersController, type: :controller do
	before(:each) do 
		@game = Game.first
		@params = {user: {name: "#{rand(1000)}-name", email: "#{rand(1000)}@test.com", password: 'password', password_confirmation: 'password_confirmation', game_id: @game.id, character_type: 'Lord'}}
		@hero = User.create!(name: 'Test', email: "#{rand(10000)}@test.com", password: "password", password_confirmation: "password", character_type: "Hero", game: Game.first)
	end

	after(:each) do
		@hero.destroy
	end

	describe "POST #create" do
		it "responds successfully" do 
			post :create, @params
			expect(response).to be_success
		end
	end

	describe "PUT #update" do 
		it "responds successfully" do 
			put :update, @params.merge({id: @hero.id})
			expect(response).to be_success
		end
	end

	describe "GET #confirm" do 
		it "responds successfully" do 
			expect(@hero.confirmation_token.blank?).to eq(false)
			get :confirm, {token: @hero.confirmation_token}
			expect(response).to be_success
			@hero.reload
			expect(@hero.confirmed).to eq(true)
		end
	end
end
