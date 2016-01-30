module Races
	extend ActiveSupport::Concern

	# Race building points
	# - Every race gets 6 free points
	# - +10: Rare
	# - +8: Weak
	# - +6
	# - +4: Elemental
	# - +2: Slow, Flighty, Stupid, Huge, Mountain
	# - +1: Slight, Large
	# - -1: Small, Curious, Stubborn
	# - -2: Fast, Resilient, Stealthy, Tiny
	# - -4: Smart, Evasive, Indomitable, Terrifying, Flying, Swimming
	# - -6: Versatile, Tough
	# - -8: Undead
	# - -10: Frisky, Strong
	#
	# - Human (6): Versatile (6)
	# - Elf (6): Fast (2), Smart (4)
	# - Dwarf (6): Resilient (2), Slow(-2) Tough (6)
	# - Orc (6): Stupid(-2), Tough (6), Resilient (2)
	# - Goblin (6): Fast (2), Flighty(-2), Frisky(10), Small (1), Weak (-8), Evasive (4)
	# - Ogre (6): Large (-1), Rare (-10), Slow(-2), Strong(10), Stupid(-2), Tough(6), Terrifying (4), Slow(-2), Stubborn (1)
	# - Giant (6): Huge (-2), Rare (-10), Slow(-2), Strong(10), Tough(6), Resilient (3), Mountain (-2), Stubborn (1)
	# - Skeleton (4): Undead (8), Weak (-8), Evasive (4)
	# - Zombie (8): Undead(8), Slow (-2), Stupid(-2), Indomitable(4)
	# - Vampire (6): Undead(8), Rare (-10), Flying (4), Smart (4)
	# - Imp (6): Frisky (10), Elemental (-4), Tiny (2), Weak (-8), Evasive (4), Stealthy (2)
	# - Serpent (6): Swimming (4), Elemental (-4), Fast (2), Resilient(2), Stealthy (2)
	# - Valkyrie (6): Fast (2), Flying (4), Elemental (-4), Resilient(2), Terrifying (4), Mountain (-2)
	

	HUMANOIDS = ['Human', 'Elf', 'Dwarf', 'Orc', 'Goblin', 'Ogre', 'Giant']
	UNDEAD = ['Skeleton', 'Zombie', 'Vampire']
	ELEMENTAL = ['Imp', 'Serpent', 'Valkyrie']
	SPECIAL_RACES = ['Character']
	
	ALL_RACES = HUMANOIDS + UNDEAD + ELEMENTAL + SPECIAL_RACES

	VERSATILE_RACES = ['Human']
	EVASIVE_RACES = ['Goblin', 'Imp', 'Skeleton']
	STRONG_RACES = ['Ogre','Giant']
	SLIGHT_RACES = []
	WEAK_RACES = ['Goblin', 'Skeleton', 'Imp']
	TOUGH_RACES = ['Dwarf', 'Orc', 'Ogre', 'Zombie', 'Giant']
	FAST_RACES = ['Elf','Goblin','Serpent','Valkyrie']
	SLOW_RACES = ['Dwarf', 'Giant', 'Ogre', 'Zombie']
	RESILIENT_RACES = ['Dwarf', 'Giant', 'Orc', 'Serpent', 'Valkyrie']
	FLIGHTY_RACES = ['Goblin']
	SMART_RACES = ['Elf', 'Vampire']
	CURIOUS_RACES = []
	STUPID_RACES = ['Orc', 'Ogre', 'Zombie']
	FRISKY_RACES = ['Goblin','Imp']
	RARE_RACES = ['Giant', 'Ogre', 'Vampire']
	TINY_RACES = ['Imp']
	SMALL_RACES = ['Goblin']
	LARGE_RACES = ['Ogre']
	HUGE_RACES = ['Giant']
	FLYING_RACES = ['Vampire','Valkyrie']
	SWIMMING_RACES = ['Serpent']
	STEALTHY_RACES = ['Imp', 'Serpent']
	TERRRIFYING_RACES = ['Ogre', 'Valkyrie']
	INDOMITABLE_RACES = ['Zombie']
	STUBBORN_RACES = ['Giant', 'Ogre']

	included do
		ALL_RACES.each do |race|
			define_method("race_#{race.downcase}?") do 
				self.race == race
			end

			scope race.downcase.to_sym, -> { where({race: race})}
		end
	end

	def valid_race?
		self.race && ALL_RACES.include?(self.race)
	end

	def humanoid?
		HUMANOIDS.include?(self.race)
	end

	def undead?
		UNDEAD.include?(self.race)
	end

	def elemental?
		ELEMENTAL.include?(self.race)
	end

	def versatile?
		VERSATILE_RACES.include?(self.race)
	end

	def strong?
		STRONG_RACES.include?(self.race)
	end

	def slight?
		SLIGHT_RACES.include?(self.race)
	end

	def weak?
		WEAK_RACES.include?(self.race)
	end

	def tough?
		TOUGH_RACES.include?(self.race)
	end

	def fast?
		FAST_RACES.include?(self.race)
	end

	def slow?
		SLOW_RACES.include?(self.race)
	end

	def resilient?
		RESILIENT_RACES.include?(self.race)
	end

	def flighty?
		FLIGHTY_RACES.include?(self.race)
	end

	def smart?
		SMART_RACES.include?(self.race)
	end

	def curious?
		CURIOUS_RACES.include?(self.race)
	end

	def stupid?
		STUPID_RACES.include?(self.race)
	end

	def frisky?
		FRISKY_RACES.include?(self.race)
	end

	def rare?
		RARE_RACES.include?(self.race)
	end

	def tiny?
		TINY_RACES.include?(self.race)
	end

	def small?
		SMART_RACES.include?(self.race)
	end

	def large?
		LARGE_RACES.include?(self.race)
	end

	def huge?
		HUGE_RACES.include?(self.race)
	end

	def flying?
		FLYING_RACES.include?(self.race)
	end

	def swimming?
		SWIMMING_RACES.include?(self.race)
	end

	def evasive?
		EVASIVE_RACES.include?(self.race)
	end

	def stealthy?
		STEALTHY_RACES.include?(self.race)
	end

	def terrifying?
		TERRRIFYING_RACES.include?(self.race)
	end

	def indomitable?
		INDOMITABLE_RACES.include?(self.race)
	end

	def stubborn?
		STUBBORN_RACES.include?(self.race)
	end

	def base_race_strength
		n = 4
		n += 6 if strong?
		n -= 2 if weak?
		n += 1 if versatile?
		n -= 1 if slight?
		n
	end

	def base_race_armour
		n = 4
		n += 3 if tough?
		n -= 2 if weak?
		n += 1 if versatile?
		n
	end

	def base_race_speed
		n = 4
		n += 2 if fast?
		n -= 2 if slow?
		n += 1 if versatile?
		n
	end

	def base_race_morale
		n = 4
		n += 2 if resilient?
		n -= 2 if flighty?
		n += 2 if versatile?
		n
	end

	def base_race_scouting
		n = 4
		n += 3 if smart?
		n -= 2 if stupid?
		n += 1 if versatile?
		n += 1 if curious?
		n
	end

	def race_stats_table
		"<table class='table table-striped'>
			<thead>
				<tr>
					<th>Strength</th>
					<th>Armour</th>
					<th>Speed</th>
					<th>Morale</th>
					<th>Scouting</th>
				</tr>
			</thead>
			<tbody>
				<tr>
					<td>#{self.base_race_strength}</td>
					<td>#{self.base_race_armour}</td>
					<td>#{self.base_race_speed}</td>
					<td>#{undead? ? '-' : self.base_race_morale}</td>
					<td>#{self.base_race_scouting}</td>
				</tr>
			</tbody>
		</table>"
	end

end