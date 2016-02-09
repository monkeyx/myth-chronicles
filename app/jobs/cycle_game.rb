class CycleGame
	include Resque::Plugins::Status

	attr_accessor :game

	@queue = :cycle

	def self.schedule(game)
		create(id: game.id)
	end

	def perform
		self.game = Game.where(id: options['id']).first
		if self.game
			tick("#{self.game} - #{self.game.game_time}")
			begin
				Rails.logger.info "Cycle Game: #{self.game}: START"
				self.game.transaction do 
					self.game.next_cycle!
					CycleGame.spawn_barbarians!(self.game)
					CycleGame.character_pool_generation!(self.game)
					CycleGame.character_challenge_expiration!(self.game)
					CycleGame.unit_health_regeneration!(self.game)
					CycleGame.city_resource_generation!(self.game)
					CycleGame.settlement_recruitment!(self.game)
					CycleGame.trade_caravans!(self.game)
					CycleGame.propagate_rumours!(self.game)
					CycleGame.cleanup!(game)
					CycleGame.send_updates!(game)
				end
				completed("#{self.game} - #{self.game.game_time}")
				Rails.logger.info "Cycle Game: #{self.game}: FINISH"
			rescue => e
				failed(e.to_s)
				Rails.logger.error "Cycle Game: #{options['id']}: ERROR #{e}"
				Rails.logger.error e.backtrace
			end
		end
	end

	def self.spawn_barbarians!(game)
		Rails.logger.info "Cycle Game: #{game}: Spawn Barbarians"
		game.neutral_cities.times do
			Position.create_barbarian!(game)
		end
	end

	def self.move_barbarians!(game)
		Rails.logger.info "Cycle Game: #{game}: Move Barbarians"
		Position.in_game(game).army.barbarian.find_each do |barbarian|
			hex = Hex.in_game(game).around(barbarian.location).not_impassable.to_a.sample
			barbarian.army.move!(hex.location) if hex
		end
	end

	def self.character_pool_generation!(game)
		Rails.logger.info "Cycle Game: #{game}: Character Pool Regeneration"
		Character.in_game(game).find_each do |character|
			if character.cycle_generation!
				ActionReport.add_report!(character, 'Regeneration', I18n.translate("cycles.character.regeneration", {character: character, action_points: character.action_points, mana_points: character.mana_points}), character)
			end
		end
	end

	def self.character_challenge_expiration!(game)
		Rails.logger.info "Cycle Game: #{game}: Character Challenge Expiration"
		CharacterChallenge.in_game(game).find_each do |challenge|
			if challenge.expired?
				challenge.reject!
				ActionReport.add_report!(challenge.character, 'Expired Challenge', I18n.translate("cycles.character.challenge.expired", {character: character, challenger: challenge.challenger}), challenge.challenger)
				ActionReport.add_report!(challenge.challenger, 'Expired Challenge', I18n.translate("cycles.character.challenge.expired-challenger", {character: challenge.character, challenger: challenge.challenger}), challenge.character)
			end
		end
	end

	def self.unit_health_regeneration!(game)
		Rails.logger.info "Cycle Game: #{game}: Unit Health Regeneration"
		Army.in_game(game).find_each do |army|
			count = 0
			fully_healed = 0
			Unit.for_army(army).damaged.find_each do |unit|
				health = unit.health + unit.health_regeneration_rate
				health = 100 if health > 100
				unit.update_attributes!(health: health)
				count += 1
				fully_healed += 1 if unit.health == 100
			end
			if count > 0
				ActionReport.add_report!(army, 'Units Healed', I18n.translate("cycles.army.units-healed", {army: army, count: count, fully_healed: fully_healed}), army)
			end
		end
	end

	def self.city_resource_generation!(game, skip_action_report=false)
		Rails.logger.info "Cycle Game: #{game}: City Resource Generation"
		Settlement.in_game(game).city.find_each do |city|
			resources = city.produce_resources!
			ActionReport.add_report!(city, 'Resource Production', I18n.translate("cycles.settlement.resources-produced", {settlement: city}.merge(resources)), city) unless skip_action_report
		end
	end

	def self.settlement_recruitment!(game)
		Rails.logger.info "Cycle Game: #{game}: Settlement Recruitment"
		Settlement.in_game(game).find_each do |settlement|
			recruitment_rate = settlement.recruit!
			if recruitment_rate > 0
				ActionReport.add_report!(settlement, 'Recruitment', I18n.translate("cycles.settlement.recruitment", {settlement: settlement, item: settlement.recruitment_race_item, quantity: recruitment_rate}), settlement)
			end
		end
	end

	def self.trade_caravans!(game)
		Rails.logger.info "Cycle Game: #{game}: Trade Caravans"
		Buy.in_game(game).find_each do |buy|
			buy.complete_sale!
		end
	end

	def self.propagate_rumours!(game)
		Rails.logger.info "Cycle Game: #{game}: Propogate Rumours"
		Rumour.in_game(game).find_each do |rumour|
			if rumour.expired?
				rumour.destroy
			else
				rumour.spread!
			end
		end
	end

	def self.cleanup!(game)
		Rails.logger.info "Cycle Game: #{game}: Cleanup"
		Army.empty.find_each do |army|
			ActionReport.add_report!(army.owner, 'Army Disbanded', I18n.translate("cycles.army.disbanded", {army: army}), army)
			army.destroy
		end
	end

	def self.send_updates!(game)
		Rails.logger.info "Cycle Game: #{game}: Send Updates"
		User.in_game(game).find_each do |user|
			user.send_update!
		end
	end
end