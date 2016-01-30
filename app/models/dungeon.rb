class Dungeon < ActiveRecord::Base
	include Spatial

	CHALLENGE_TYPE = {
		'fighting monsters' => :strength_rating,
		'a trap' => :cunning_rating,
		'a puzzle' => :craft_rating
	}
	
	validates :name, length: {in: 1..50}
	belongs_to :game
	validates :max_levels, numericality: {only_integer: true, greater_than_or_equal_to: 0}

	def self.create_dungeon!(game, x, y, name="Dungeon",max_levels=(rand(20) + 1))
		dungeon = create!(game: game, x: x, y: y, name: name, max_levels: max_levels)
		Rails.logger.info("CREATED #{dungeon}")
		dungeon
	end

	def challenge(character, level)
		challenge_type = CHALLENGE_TYPE.keys.sample
		attribute = CHALLENGE_TYPE[challenge_type]
		target = 4 + (2 * level)
		return challenge_type, character.check_attribute(attribute, target)
	end

	def to_s
		"#{name} (#{id})"
	end

	def as_json(options={})
		{
			id: id,
			name: name,
			location: location
		}
	end
end
