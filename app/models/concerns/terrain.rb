module Terrain
	extend ActiveSupport::Concern

	ALL_TERRAIN = ['Barren','Desert','Forest','Hill','Mountain', 'Plains', 'River', 'Scrubland', 'Sea', 'Swamp', 'Volcano','Wasteland']

	DIFFICULT_TERRAIN = ['Desert', 'Forest', 'Hill', 'River', 'Swamp']

	DEFENSIVE_TERRAIN = ['Forest', 'Hill', 'Mountain', 'River']

	IMPASSABLE_TERRAIN = ['Mountain', 'Sea', 'Volcano']

	WATER_TERRAIN = ['River', 'Sea']

	HIDE_TERRAIN = {
		'Forest' => 0.5,
		'Plains' => 1,
		'River' => 0.25
	}

	IRON_TERRAIN = {
		'Barren' => 0.5,
		'Hill' => 0.25,
		'Mountain' => 1
	}

	STONE_TERRAIN = {
		'Barren' => 0.25,
		'Hill' => 1,
		'Mountain' => 0.5
	}

	WOOD_TERRAIN = {
		'Forest' => 1,
		'Swamp' => 0.25,
		'Scrubland' => 0.5
	}
	

	RACE_TERRAIN_CITY_RECRUITMENT = {
		'Human' => 'Plains',
		'Elf' => 'Forest', 
		'Dwarf' => 'Hill',  
		'Orc' => 'Barren', 
		'Goblin' => 'Scrubland',  
		'Ogre' => 'Wasteland',  
		'Giant' => 'Mountain'
	}

	CITY_TERRAIN_RECRUITMENT = RACE_TERRAIN_CITY_RECRUITMENT.invert

	RACE_TERRAIN_LAIR_RECRUITMENT = {
		'Imp' => 'Desert', 
		'Serpent' => 'Sea', 
		'Valkyrie' => 'Mountain'
	}

	LAIR_TERRAIN_RECRUITMENT = RACE_TERRAIN_LAIR_RECRUITMENT.invert

	RACE_TERRAIN_TOWER_RECRUITMENT = {
		'Skeleton' => 'Plains',  
		'Zombie' => 'Forest',  
		'Vampire' => 'Mountain'
	}

	TOWER_TERRAIN_RECRUITMENT = RACE_TERRAIN_TOWER_RECRUITMENT.invert

	VALID_TERRAIN_FOR_SETTLEMENTS = {
		'City' => Settlement::VALID_CITY_TERRAIN,
		'Lair' => Settlement::VALID_LAIR_TERRAIN,
		'Tower' => Settlement::VALID_TOWER_TERRAIN
	}

	BEAST_TERRAIN_TAMING =	{'Mountain' => 'Gryphon', 
		'Plains' => 'Horse', 
		'Forest' => 'Wolf'}

	included do
		validates :terrain, inclusion: {in: [''] + ALL_TERRAIN}
		
		scope :of_terrain, ->(terrain) { where(terrain: terrain )}
		scope :not_terrain, ->(terrain) { where(["terrain <> ?", terrain] )}
		scope :any_of_terrains, ->(terrains) { where(["terrain IN (?)", terrains])}
		scope :not_any_of_terrains, ->(terrains) { where(["terrain NOT IN (?)", terrains])}
		scope :water, -> { any_of_terrains(WATER_TERRAIN) }
		scope :not_water, -> { not_any_of_terrains(WATER_TERRAIN) }
		scope :not_impassable, -> { not_any_of_terrains(IMPASSABLE_TERRAIN) }
	end

	def water?
		Terrain::WATER_TERRAIN.include?(self.terrain)
	end

	def difficult?
		(self.respond_to?(:game) ? self.game.season_difficult_terrain?  : false) || DIFFICULT_TERRAIN.include?(self.terrain)
	end

	def defensive?
		Terrain::DEFENSIVE_TERRAIN.include?(self.terrain)
	end

	def impassable?
		Terrain::IMPASSABLE_TERRAIN.include?(self.terrain)
	end

	def valid_for_settlement?(settlement_type)
		Terrain::VALID_TERRAIN_FOR_SETTLEMENTS[settlement_type].include?(self.terrain)
	end

	def terrain_city_recruitment
		Terrain::CITY_TERRAIN_RECRUITMENT[self.terrain]
	end

	def terrain_lair_recruitment
		Terrain::LAIR_TERRAIN_RECRUITMENT[self.terrain]
	end

	def terrain_tower_recruitment
		Terrain::TOWER_TERRAIN_RECRUITMENT[self.terrain]
	end
end