class Rumour < ActiveRecord::Base
	RUMOUR_EXPIRATION = 16
	RUMOUR_TYPES = ['Alliance News', 'Barbarians', 'Character Death', 'Battle', 'Settlement Formed', 'Settlement Razed', 'Disaster']

	include Spatial
	include Temporal
	
	validates :spread_rate, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :current_distance, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :summary, presence: true
	
	belongs_to :alliance

	has_many :character_rumours, dependent: :destroy

	validates :rumour_type, inclusion: {in: RUMOUR_TYPES}

	def self.publish_news!(character, text)
		r = Rumour.new(spread_rate: character.cunning_rating, rumour_type: 'Alliance News')
		r.summary = text
		r.location = character.location
		r.game_time = character.game.game_time
		r.alliance = character.alliance
		r.save!
		r
	end

	def self.report_character_death!(character, reason)
		r = Rumour.new(rumour_type: 'Character Death')
		r.summary = "#{character} died at ##{character.location} #{reason}"
		r.location = character.location
		r.game_time = character.game.game_time
		r.save!
		r
	end

	def self.report_settlement_formed!(settlement)
		r = Rumour.new(rumour_type: 'Settlement Formed')
		r.summary = "#{settlement.settlement_type} #{settlement} formed at ##{settlement.location}"
		r.location = settlement.location
		r.game_time = settlement.game.game_time
		r.save!
		r
	end

	def self.report_settlement_razed!(settlement)
		r = Rumour.new(rumour_type: 'Settlement Razed')
		r.summary = "#{settlement.settlement_type} #{settlement} razed at ##{settlement.location}"
		r.location = settlement.location
		r.game_time = settlement.game.game_time
		r.save!
		r
	end

	def self.report_combat!(attacker, defender)
		r = Rumour.new(rumour_type: 'Battle')
		r.summary = "A battle was fought between #{attacker} and #{defender} at ##{attacker.location}"
		r.location = attacker.location
		r.game_time = attacker.game.game_time
		r.save!
		r
	end

	def self.report_disaster!(game_time, location, summary)
		r = Rumour.new(rumour_type: 'Disaster')
		r.summary = summary
		r.location = location
		r.game_time = game_time
		r.save!
		r
	end

	def self.report_barbarians!(game_time, location)
		r = Rumour.new(rumour_type: 'Barbarians')
		r.summary = "Barbarians have formed an army at ##{location}"
		r.location = location
		r.game_time = game_time
		r.spread_rate = 2
		r.save!
		r
	end

	def expired?
		(self.game_time + RUMOUR_EXPIRATION) < self.game.game_time
	end

	def spread!
		update_attributes!(current_distance: (self.current_distance + self.spread_rate))
		Character.in_game(self.game).around_block(self.x, self.y, self.current_distance).each do |character|
			unless CharacterRumour.for_character(character).for_rumour(self).count > 0
				ActionReport.add_report!(character, "#{self.rumour_type}", self.summary, character)
				CharacterRumour.create!(character: character, rumour: self, location: character.location, game: self.game, game_time: self.game.game_time)
			end
		end
	end
end
