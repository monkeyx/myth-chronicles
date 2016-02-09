class Character < ActiveRecord::Base
	CHARACTER_TYPE = ['Hero', 'Lord', 'Necromancer', 'Dragon']
	
	CHARACTER_SETTLEMENT_TYPE = {
		'Hero' => 'Guild', 
		'Lord' => 'City', 
		'Necromancer' => 'Tower', 
		'Dragon' => 'Lair'
	}

	CHARACTER_SUBTYPE_EQUIPMENT_SLOTS = {
		'Hero' => [:armour, :weapon, :ring, :amulet], 
		'Lord' => [:armour, :weapon, :amulet], 
		'Necromancer' => [:weapon, :ring, :amulet], 
		'Dragon' => [:ring, :amulet]
	}

	CHARACTER_SPELLS = {
		'Hero' => ['Bless', 'Heal', 'Teleport'], 
		'Lord' => ['Bless', 'Heal'], 
		'Necromancer' => ['Heal', 'Ritual', 'Scry', 'Teleport'], 
		'Dragon' => ['Ritual', 'Scry']
	}

	IMMORTALITY_NECROMANCER_ITEMS = {
		'Human' => 10000,
		'Elf' => 10000,
		'Dwarf' => 10000,
		'Orc' => 10000,
		'Goblin' => 10000
	}

	IMMORTALITY_NECROMANCER_MANA = 500
	IMMORTALITY_DRAGON_GOLD = 1000000
	IMMORTALITY_LORD_CAPITALS = 10

	BLESS_PER_MANA_CRAFT_FACTORS = 0.04
	HEAL_PER_MANA_CRAFT_FACTORS = 0.05
	RITUAL_MANA_POINTS_PER_STAT_MODIFIER = 50
	RITUAL_CRAFTING_COST_PER_MAGIC_ITEM = 1
	SCRY_MANA_COST_MULTIPLIER = 5
	TELEPORT_MANA_COST_MULTIPLIER = 30

	INSPIRATION_LOYALTY_BOOST = 10

	MANA_POINTS_PER_TOWER_OR_LAIR = 2

	CHARACTER_ATTRIBUTES = [:strength_rating, :armour_rating, :speed_rating, :leadership_rating, :cunning_rating, :craft_rating]

	CHARACTER_ATTRIBUTES.each do |attr|
		validates attr, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	end

	CHARACTER_EQUIPMENT_SLOTS = [:armour, :weapon, :ring, :amulet]

	CHARACTER_EQUIPMENT_SLOTS.each do |slot|
		belongs_to slot, class_name: 'Item'
	end

	validate :validate_equipment

	POINT_POOLS = [:action_points, :mana_points, :experience_points, :renown, :gold]
	
	POINT_POOLS.each do |pool|
		validates pool, numericality: {only_integer: true}
	end

	include AttributeCheck
	include PositionType
	include Combat
	
	validates :character_type, inclusion: {in: CHARACTER_TYPE}

	belongs_to :alliance

	belongs_to :user

	has_one :unit, dependent: :destroy
	has_one :army, through: :unit
	has_many :dungeon_exploreds, foreign_key: 'hero_id', dependent: :destroy
	has_many :positions, foreign_key: 'owner_id', dependent: :destroy
	has_many :challenges_received, dependent: :destroy, class_name: 'CharacterChallenge', foreign_key: 'character_id'
	has_many :challenges_given, dependent: :destroy, class_name: 'CharacterChallenge', foreign_key: 'challenger_id'
	has_many :character_rumours, dependent: :destroy
	has_many :quests, dependent: :destroy

	before_validation :setup_character_attributes
	after_create :set_user_character_type!
	after_destroy :clear_character_type_on_user!
	after_save :check_quests!

	CHARACTER_TYPE.each do |character_type|
		define_method("#{character_type.downcase}?") do 
			self.character_type == character_type
		end
	end

	POINT_POOLS.each do |pool_symbol|
		define_method("min_#{pool_symbol}") do
			0
		end

		define_method("use_#{pool_symbol}!") do |points|
			current_points = send(pool_symbol)
			if (current_points - points) < send("min_#{pool_symbol}".to_sym)
				raise "Insufficient #{pool_symbol.to_s.gsub('_',' ').capitalize}"
			end
			current_points -= points
			update_attributes!(pool_symbol => current_points)
		end

		define_method("max_#{pool_symbol}") do
			0
		end

		define_method("add_#{pool_symbol}!") do |points|
			current_points = send(pool_symbol)
			max_points = send("max_#{pool_symbol}".to_sym)
			if max_points != 0 && (current_points + points) > max_points
				update_attributes!(pool_symbol => max_points)
			else
				current_points += points
				update_attributes!(pool_symbol => current_points)
			end
		end
	end

	def get_attribute(attribute)
		raise "Invalid attribute" unless CHARACTER_ATTRIBUTES.include?(attribute)
		read_attribute(attribute)
	end

	def update_attribute(attribute, value)
		raise "Invalid attribute" unless CHARACTER_ATTRIBUTES.include?(attribute)
		write_attribute(attribute, value)
	end

	def min_renown
		-100000000000
	end

	def max_action_points
		40
	end

	def max_mana_points
		self.craft_rating * 10
	end

	def subtype
		self.character_type
	end

	def settlement_type
		CHARACTER_SETTLEMENT_TYPE[self.character_type]
	end

	def settlements
		Settlement.owned_by(self)
	end

	def armies
		Army.owned_by(self)
	end

	def range
		return 2 if necromancer?
		0
	end

	def movement_type
		return 'Air' if dragon?
		'Land'
	end

	def create_unit!
		army = Position.create_army!(self.game, self, "#{self.name}'s Army")
		Unit.create_character_unit!(army, self)
	end

	def setup_character_attributes
		if new_record?
			case self.character_type
			when 'Hero'
				self.strength_rating = 7
				self.armour_rating = 7
				self.leadership_rating = 5
				self.cunning_rating = 5
				self.craft_rating = 5
				self.speed_rating = 5
			when 'Lord'
				self.strength_rating = 5
				self.armour_rating = 5
				self.leadership_rating = 7
				self.cunning_rating = 7
				self.craft_rating = 3
				self.speed_rating = 3
			when 'Necromancer'
				self.strength_rating = 3
				self.armour_rating = 3
				self.leadership_rating = 5
				self.cunning_rating = 5
				self.craft_rating = 10
				self.speed_rating = 3
			when 'Dragon'
				self.strength_rating = 10
				self.armour_rating = 10
				self.leadership_rating = 3
				self.cunning_rating = 3
				self.craft_rating = 5
				self.speed_rating = 5
			end
			self.action_points = 40
			self.mana_points = self.craft_rating * 10
		end
	end

	#
	# Challenges
	#

	def challenges
		CharacterChallenge.for_character(self)
	end

	def challenge!(other_character)
		raise "Invalid character" unless other_character && other_character.is_a?(Character)
		challenge = CharacterChallenge.new(challenger: self, character: other_character)
		challenge.location = self.location
		challenge.game = self.game
		challenge.game_time = self.game.game_time
		challenge.save!
		challenge
	end

	#
	# Magic
	#

	def can_cast?(spell)
		CHARACTER_SPELLS[self.character_type].include?(spell)
	end

	#
	# Equipment
	#

	def slot_available?(slot)
		CHARACTER_SUBTYPE_EQUIPMENT_SLOTS[self.character_type].include?(slot)
	end

	def can_wear?(item)
		item && slot_available?(item.magical_type.to_sym)
	end

	def equip!(item)
		if item.armour?
			self.armour = item 
		end
		if item.weapon?
			self.weapon = item 
		end
		if item.ring? 
			self.ring = item
		end
		if item.amulet?
			self.amulet = item 
		end
		save!
	end

	def validate_equipment
		CHARACTER_EQUIPMENT_SLOTS.each do |slot|
			unless send(slot).nil? || CHARACTER_SUBTYPE_EQUIPMENT_SLOTS[self.character_type].include?(slot)
				errors.add(slot, "invalid for #{self.character_type}")
			end
		end
	end

	#
	# Dungeons
	#
	def level_explored(dungeon)
		raise "Invalid dungeon" unless dungeon
		raise "Invalid character" unless hero?
		de = DungeonExplored.for_hero(self).for_dungeon(dungeon).first
		de.nil? ? 0 : de.level
	end

	def set_level_explored!(dungeon, level)
		raise "Invalid dungeon" unless dungeon
		raise "Invalid character" unless hero?
		de = DungeonExplored.for_hero(self).for_dungeon(dungeon).first
		de ||= DungeonExplored.new(hero: self, dungeon: dungeon)
		de.level = level
		de.save!
	end

	#
	# Incapitation and death
	# 
	def incapacitated!
		return false if self.settlements.count < 1
		transaction do 
			new_location = self.settlements.first.location
			army = self.army
			if self.army.units.count > 1
				army = Position.create_army!(self.game, self, "#{self.name}'s Army")
			end
			self.unit.update_attributes!(army: army, health: 50)
			army.location = new_location
			army.save!
		end
	end

	def die!(reason)
		transaction do
			self.positions.each do |pos|
				if pos.army
					pos.destroy 
				elsif pos.settlement
					pos.update_attributes!(owner_id: 0)
				end
			end
			Rumour.report_character_death!(self, reason)
			self.user.send_character_killed!(self, reason) if SEND_EMAILS
			destroy
		end
	end

	#
	# Pool Generation
	#
	def cycle_generation!
		changed = false
		transaction do
			unless max_mana_points == self.mana_points
				changed = true
				add_mana_points!(self.game.mana_points_generated)
				if dragon? || necromancer?
					add_mana_points!((MANA_POINTS_PER_TOWER_OR_LAIR * settlements.count))
				end
			end
			unless max_action_points == self.action_points
				changed = true
				add_action_points!(self.game.action_points_generated)
			end
		end
		changed
	end

	def check_quests!
		self.quests.each do |q|
			q.check_and_complete!
		end
	end

	def give_first_quest!
		case self.character_type
		when 'Lord'
			Quest.give_quest!(self, PropertyChangeQuest, 'L01ChangeName')
		when 'Hero'
			Quest.give_quest!(self, PropertyChangeQuest, 'H01ChangeName')
		when 'Dragon'
			Quest.give_quest!(self, PropertyChangeQuest, 'D01ChangeName')
		when 'Necromancer'
			Quest.give_quest!(self, PropertyChangeQuest, 'N01ChangeName')
		end
	end

	def colour
		"##{self.user.colour}"
	end

	def set_user_character_type!
		self.user.update_attributes!(character_type: self.character_type, setup_complete: false)
	end

	def clear_character_type_on_user!
		self.user.update_attributes!(character_type: '', setup_complete: false)
	end

	def as_json(options={})
		self.position.as_json(options.merge({full: true})).merge({
			icon: character_type.downcase,
			army: {
				id: army ? army.id : nil,
				name: army ? army.name : nil
			},
			strength_rating: strength_rating,
			armour_rating: armour_rating,
			leadership_rating: leadership_rating,
			cunning_rating: cunning_rating,
			craft_rating: craft_rating,
			speed_rating: speed_rating,
			armour: armour,
			weapon: weapon,
			ring: ring,
			amulet: amulet,
			action_points: action_points,
			mana_points: mana_points,
			gold: ActionController::Base.helpers.number_with_delimiter(gold),
			renown: renown,
			experience_points: experience_points,
			alliance: alliance,
			positions: positions.map{|p| {id: p.id, name: p.name, type: p.position_type, subtype: p.subtype }},
			challenges: challenges,
			dungeons: dungeon_exploreds,
			army_count: Army.owned_by(self).count,
			settlement_count: Settlement.owned_by(self).count
		})
	end
end
