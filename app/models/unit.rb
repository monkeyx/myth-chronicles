class Unit < ActiveRecord::Base
	include AttributeCheck
	include Races
	include Tactics
	include Training

	MINIMUM_ITEM_QUANTITY = 100
	GOLD_COST_TO_CREATE = 10
	MANA_COST_TO_CREATE = 10
	GOLD_COST_TO_TRAIN = 100

	UNIT_ATTRIBUTES = [:strength_rating, :armour_rating, :speed_rating, :morale_rating, :scouting_rating, :bless_rating]

	UNIT_ATTRIBUTES.each do |attr|
		validates attr, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	end

	validates :health, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100}
	validates :range, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 2}

	UNIT_EQUIPMENT_SLOTS = [:armour, :weapon, :mount, :transport, :siege_equipment]

	UNIT_EQUIPMENT_SLOTS.each do |slot|
		belongs_to slot, class_name: 'Item'
	end

	validate :validate_equipment
	
	belongs_to :army
	
	validates :race, inclusion: {in: ALL_RACES }
	validates :training, inclusion: {in: ALL_TRAINING }
	validates :tactic, inclusion: {in: ALL_TACTICS }

	validate :validate_tactics
	
	belongs_to :character

	scope :for_army, ->(army) { where({army: army})}
	scope :melee, -> { where({range: 0})}
	scope :short_range, -> { where({range: 1})}
	scope :long_range, -> { where({range: 2})}
	scope :damaged, -> { where("health < 100")}
	
	before_save :calculate_previous!
	before_save :check_equipment_validity
	after_save :calculate_army!
	after_create :calculate_army!
	after_destroy :calculate_army!

	default_scope { joins(:army) }

	def self.create_character_unit!(army, character)
		create!(army: army, race: 'Character', health: 100, range: character.range, morale_rating: character.leadership_rating, 
			scouting_rating: character.cunning_rating, strength_rating: character.strength_rating, armour_rating: character.armour_rating, 
			speed_rating: character.speed_rating, character: character)
	end

	def self.create_unit!(army, item)
		create!(army: army, race: item.race, health: 100, range: 0, morale_rating: item.base_race_morale, 
			scouting_rating: item.base_race_scouting, strength_rating: item.base_race_strength, armour_rating: item.base_race_armour, 
			speed_rating: item.base_race_speed)
	end

	#
	# Equipment
	#

	def equip!(item)
		raise "Invalid item" unless item && can_equip?(item)
		if item.armour
			self.armour = item
		end
		if item.weapon
			self.weapon = item 
		end
		if item.vehicle 
			self.transport = item 
		end
		if item.siege_equipment
			self.siege_equipment = item 
			if self.mount 
				self.army.add_items!(self.mount, MINIMUM_ITEM_QUANTITY)
				self.mount = nil
			end
		end
		if item.beast 
			self.mount = item 
			if self.siege_equipment
				self.army.add_items!(self.siege_equipment, MINIMUM_ITEM_QUANTITY)
				self.siege_equipment = nil
			end
		end
		save!
	end

	def can_equip?(item)
		return false unless item && item.equippable?
		return false if !item.training_required.blank? && self.training != item.training_required
		return false if item.mounted_only && self.mount.nil?
		return false if flying? && item.siege_equipment
		return false if item.beast? && (flying? || large? || huge? || swimming?)
		return false if item.speed_rating + adjusted_speed_rating < 0
		return true if item.vehicle || item.siege_equipment
		return true if humanoid?
		return true if undead? && (item.armour || item.weapon)
		return false
	end

	def validate_equipment
		if self.armour 
			errors.add(:armour, "Invalid item") unless self.armour.armour && (humanoid? || undead?)
		end
		if self.weapon 
			errors.add(:weapon, "Invalid item") unless self.weapon.weapon && (humanoid? || undead?)
		end
		if self.mount 
			errors.add(:mount, "Invalid item") unless self.mount.beast && humanoid?
		end
		if self.transport 
			errors.add(:transport, "Invalid item") unless self.transport.vehicle
		end
		if self.siege_equipment
			errors.add(:siege_equipment, "Invalid item") unless self.siege_equipment.siege_equipment
		end
	end

	def check_equipment_validity
		if self.armour && !can_equip?(self.armour)
			self.army.add_items!(self.armour, 100)
			self.armour = nil 
		end
		if self.weapon && !can_equip?(self.weapon)
			self.army.add_items!(self.weapon, 100)
			self.weapon = nil 
		end
		if self.mount && !can_equip?(self.mount)
			self.army.add_items!(self.mount, 100)
			self.mount = nil 
		end
		if self.siege_equipment && !can_equip?(self.siege_equipment)
			self.army.add_items!(self.siege_equipment, 100)
			self.siege_equipment = nil 
		end
		if self.transport && !can_equip?(self.transport)
			self.army.add_items!(self.transport, 100)
			self.transport = nil 
		end
	end

	#
	# Tactics
	#

	def can_adopt_tactic?(tactic)
		TRAINING_FOR_TACTIC[tactic].blank? || TRAINING_FOR_TACTIC[tactic] == self.training
	end

	def validate_tactics
		errors.add(:tactic, 'invalid due to lack of training') unless can_adopt_tactic?(self.tactic)
	end

	#
	# Regeneration
	#

	def health_regeneration_rate
		return 0 if self.health == 100
		1 + (self.army.in_friendly_territory? ? 4 : 0)
	end

	def location
		self.army.location 
	end

	def calculate_previous!
		if self.army_id != self.army_id_was
			previous_army = Army.where(id: self.army_id_was).first
			previous_army.calculate! if previous_army 
		end
	end

	def calculate_army!
		self.army && self.army.calculate!
	end

	def training_cost
		cost = GOLD_COST_TO_TRAIN
		cost *= 3 if stupid?
		cost /= 2 if smart?
		cost
	end

	def to_s
		s = self.character ? self.character.to_s : self.race.pluralize 
		if self.weapon && self.armour 
			s = "#{self.weapon.name}-#{self.armour.name} #{s}"
		elsif self.weapon
			s = "#{self.weapon.name} #{s}"
		elsif self.armour
			s = "#{self.armour.name} #{s}"
		end
		s = "#{s} on #{self.mount.name.downcase.pluralize}" if self.mount
		s
	end

	def adjusted_strength_rating
		strength_rating + (weapon.nil? ? 0 : weapon.strength_rating)
	end

	def adjusted_armour_rating
		armour_rating + (armour.nil? ? 0 : armour.armour_rating)
	end

	def adjusted_speed_rating
		speed_rating + (mount.nil? ? 0 : 3) + 
			(tactic == 'Ambush' ? 2 : 0) + (tactic == 'Flank' ? 2 : 0) +
			(armour.nil? ? 0 : armour.speed_rating) +
			(weapon.nil? ? 0 : weapon.speed_rating)
	end

	def adjusted_morale_rating
		morale_rating + (tactic == 'Wall' ? 2 : 0)
	end

	def adjusted_scouting_rating
		scouting_rating + (training == 'Reconnaissance' ? 3 : 0)
	end

	def adjusted_range
		weapon.nil? ? self.range : weapon.range
	end

	def adjusted_flying?
		flying? || (mount && (mount.flying? || mount.flying)) || (self.character && self.character.dragon?)
	end

	def adjusted_swimming?
		swimming? || (mount && mount.swimming?)
	end

	def visibility
		v = 7
		v += 5 if training == 'Infiltration'
		v += 5 if stealthy?
		v -= 3 if large?
		v -= 5 if huge?
		v += 3 if small?
		v += 5 if tiny?
		v += 2 if self.army.at_friendly_settlement?
		v += 3 if self.army.difficult?
		v += 5 if self.army.impassable?
		v
	end

	def unit_icon
		unless character || race.nil?
			return race.downcase
		end
	end

	def as_json(options={})
		{
			id: id,
			name: to_s,
			race: race,
			icon: unit_icon,
			strength_rating: adjusted_strength_rating,
			armour_rating: adjusted_armour_rating,
			speed_rating: adjusted_speed_rating,
			morale_rating: undead? ? '-' : adjusted_morale_rating,
			scouting_rating: adjusted_scouting_rating,
			bless_rating: bless_rating,
			health: health < 0 ? 0 : health,
			range: adjusted_range,
			armour: armour,
			weapon: weapon,
			mount: mount,
			transport: transport,
			siege_equipment: siege_equipment,
			training: training,
			tactic: tactic
		}
	end
end
