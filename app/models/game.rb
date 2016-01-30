class Game < ActiveRecord::Base	
	include Temporal
	
	validates :name, length: {in: 1..50}
	# last_cycle
	validates :cycle_frequency, numericality: {only_integer: true, greater_than_or_equal_to: 1}
	validates :map_size, numericality: {only_integer: true, greater_than_or_equal_to: 1}, unless: "self.map_size.nil?"
	# map_name
	# setup_complete

	before_validation :set_last_cycle

	scope :due_cycle, -> { where("now() >= (games.last_cycle + (games.cycle_frequency * interval '1 hour'))")}

	before_save :calculate_neutrals
	after_create :setup_game!
	after_save :create_forum!

	has_many :hexes, dependent: :destroy
	has_many :positions, dependent: :destroy
	has_many :users
	has_many :dungeons, dependent: :destroy
	has_many :immortals, dependent: :destroy

	scope :available_hero, -> { where("neutral_guilds > 0")}
	scope :available_lord, -> { where("neutral_cities > 0")}
	scope :available_necromancer, -> { where("neutral_towers > 0")}
	scope :available_dragon, -> { where("neutral_lairs > 0")}
	scope :open, -> { where({open: true, setup_complete: true}).where("(neutral_guilds + neutral_cities + neutral_towers + neutral_lairs) > 0")}

	def setup_game!
		#Rails.env.production? ? SetupGame.schedule(self) : SetupGame.setup!(self)
		SetupGame.setup!(self)
	end

	def character_type_available?(character_type)
		case character_type
		when 'Hero'
			return self.neutral_guilds > 0
		when 'Lord'
			return self.neutral_cities > 0
		when 'Necromancer'
			return self.neutral_towers > 0
		when 'Dragon'
			return self.neutral_lairs > 0
		end
		false
	end

	def available_new_character_types
		available = []
		available << 'Hero' if self.neutral_guilds > 0
		available << 'Lord' if self.neutral_cities > 0
		available << 'Necromancer' if self.neutral_towers > 0
		available << 'Dragon' if self.neutral_lairs > 0
		available
	end

	def calculate_neutrals
		unless new_record?
			self.neutral_guilds = Settlement.of_type('Guild').in_game(self).neutral.count
			self.neutral_cities = Settlement.of_type('City').in_game(self).neutral.count
			self.neutral_towers = Settlement.of_type('Tower').in_game(self).neutral.count
			self.neutral_lairs = Settlement.of_type('Lair').in_game(self).neutral.count
		end
	end

	def map_symbols
		rows = []
		(0..(self.map_size - 1)).each do |y|
			columns = []
			(0..(self.map_size - 1)).each do |x|
				columns << Hex.at(x,y).first.terrain_symbol
			end
			rows << columns
		end
		rows.reverse
	end

	def next_cycle!
		self.cycle += 1
		if self.cycle > 4
			self.cycle = 1
			self.season += 1
			if self.season > 4
				self.year += 1
				self.season = 1
			end
		end
		self.last_cycle = Time.now
		save!
	end

	def next_age!
		self.age += 1
		save!
	end

	def create_forum!
		return unless self.open && self.setup_complete
		unless Forem::Forum.where(title: self.name).count > 0
			category = Forem::Category.where(name: 'Chronicles').first
			Forem::Forum.create(title: self.name, description: "Discussion for players of game ##{self.id}", category_id: category.id)
		end
	end

	def forum
		@forum ||= Forem::Forum.where(title: self.name).first
	end

	def post_on_forum!(subject, text, user=User.where(email: 'gm@mythchronicles.com').first)
		t = Forem::Topic.create! ({forum: forum, subject: subject, user: user, posts_attributes: [{text: text}]})
		t.approve!
	end

	def mana_points_generated
		SEASONAL_MANA_POINTS_GENERATION[(self.season - 1)]
	end

	def action_points_generated
		SEASONAL_ACTION_POINTS_GENERATION[(self.season - 1)]
	end

	def resource_production
		SEASONAL_FOOD_PRODUCTION[(self.season - 1)]
	end

	def difficult_terrain
		SEASONAL_DIFFICULT_TERRAIN[(self.season - 1)]
	end

	def to_s
		"#{name}: #{game_time.to_s}"
	end

	def set_last_cycle
		self.last_cycle ||= Time.now
	end

	def as_json(options={})
		{
			id: id,
			name: name,
			last_cycle: last_cycle,
			cycle_frequency: cycle_frequency,
			map_name: map_name,
			map_size: map_size,
			game_time: game_time,
			available_spaces: {
				hero: self.neutral_guilds > 0,
				lord: self.neutral_cities > 0,
				necromancer: self.neutral_towers > 0,
				dragon: self.neutral_lairs > 0
			}
		}
	end
end
