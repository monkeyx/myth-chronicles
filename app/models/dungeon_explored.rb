class DungeonExplored < ActiveRecord::Base

	belongs_to :dungeon
	belongs_to :hero, class_name: 'Character'
	validates :level, numericality: {only_integer: true, greater_than_or_equal_to: 0}

	validate :validate_max_level

	scope :for_hero, ->(hero) { where({hero_id: hero.id })}
	scope :for_dungeon, ->(dungeon) { where({dungeon_id: dungeon.id })}

	def validate_max_level
		if self.dungeon && self.dungeon.max_levels < self.level 
			errors.add(:level, 'exceeds maximum levels for dungeon')
		end
	end

	def to_s
		"#{dungeon}"
	end

	def as_json(options={})
		{
			dungeon: dungeon,
			level: level
		}
	end
end
