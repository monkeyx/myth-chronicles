class Item < ActiveRecord::Base
	ARTEFACT_RANK = 20
	
	include Races
	include Terrain
	include Training
	
	validates :name, length: {in: 1..50}
	# resource
	# humanoid
	# beast
	# flying
	# undead
	# elemental
	# armour
	# weapon
	# mounted_only
	# vehicle
	# siege_equipment
	# trade_good
	# magical
	# ritualable

	validates :complexity, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :race, inclusion: {in: [''] + ALL_RACES }
	validates :training_required, inclusion: {in: ALL_TRAINING }
	validates :magical_type, inclusion: {in: [''] + Character::CHARACTER_EQUIPMENT_SLOTS.map{|s| s.to_s}}
	
	validates :armour_rating, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :strength_rating, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :speed_rating, numericality: {only_integer: true}
	validates :range, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	
	validates :sea_transport_capacity, numericality: {only_integer: true}
	validates :land_transport_capacity, numericality: {only_integer: true}
	validates :air_transport_capacity, numericality: {only_integer: true}

	validates :siege_effectiveness, numericality: {only_integer: true, greater_than_or_equal_to: 0}

	validates :stat_modified, inclusion: {in: [''] + Character::CHARACTER_ATTRIBUTES.map{|s| s.to_s}}
	validates :stat_modifier, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: ARTEFACT_RANK}

	validates :hide, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :wood, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :stone, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :iron, numericality: {only_integer: true, greater_than_or_equal_to: 0}

	validates :carry_required, numericality: {only_integer: true, greater_than_or_equal_to: 0}

	before_validation :set_name

	scope :named, ->(name) { where({name: name})}
	scope :of_race, ->(race) { where(race: race )}
	scope :of_terrain, ->(terrain) { where(terrain: terrain )}
	scope :humanoid, -> { where(humanoid: true )}
	scope :beast, -> { where(beast: true )}
	scope :undead, -> { where(undead: true )}
	scope :elemental, -> { where(elemental: true )}
	scope :magical, -> { where(magical: true)}
	scope :resource, -> { where(resource: true )}
	scope :humanoid, -> { where(humanoid: true )}
	scope :beast, -> { where(beast: true )}
	scope :flying, -> { where(flying: true )}
	scope :undead, -> { where(undead: true )}
	scope :elemental, -> { where(elemental: true )}
	scope :armour, -> { where(armour: true )}
	scope :weapon, -> { where(weapon: true )}
	scope :mounted_only, -> { where(mounted_only: true )}
	scope :vehicle, -> { where(vehicle: true )}
	scope :siege_equipment, -> { where(siege_equipment: true )}
	scope :trade_good, -> { where(trade_good: true )}
	scope :magical, -> { where(magical: true )}
	scope :not_magical, -> { where(magical: false )}
	scope :produceable, -> { where("(weapon = true OR armour = true OR vehicle = true OR siege_equipment = true OR trade_good = true)")}
	scope :ritualable, -> { where(ritualable: true)}
	scope :not_hidden, -> { where(hidden: false)}
	scope :needs_hide, -> { where("hide > 0")}
	scope :needs_wood, -> { where("wood > 0")}
	scope :needs_stone, -> { where("stone > 0")}
	scope :needs_iron, -> { where("iron > 0")}

	scope :order_by_name, -> { order("name ASC")}
	
	Character::CHARACTER_EQUIPMENT_SLOTS.each do |slot|
		define_method("#{slot}?") do 
			self.magical_type == slot.to_s
		end
	end
	
	def self.create_magic_item!(slot, stat, rank)
		item = where(magical: true, ritualable: false, hidden: true, magical_type: slot, stat_modified: stat, stat_modifier: rank).first
		item ||= create!(magical: true, ritualable: false, hidden: true, magical_type: slot, stat_modified: stat, stat_modifier: rank)
	end

	def equippable?
		self.armour || self.weapon || self.vehicle || self.beast || self.siege_equipment
	end

	def artefact?
		self.stat_modifier >= ARTEFACT_RANK
	end

	def set_name
		if self.name.blank?
			item_type = self.magical_type.to_s.capitalize
			item_type = ['Sword', 'Axe', 'Mace', 'Bow'].sample if item_type == 'Weapon'
			item_type = ['Chainmail', 'Scalemail', 'Leather', 'Platemail'].sample if item_type == 'Armour'
			item_description = ''	
			if stat_modifier == 20
				item_description = 'Artefact '
			elsif stat_modifier > 16
				item_description = 'Ancient '
			elsif stat_modifier > 14
				item_description = 'Venerable '
			elsif stat_modifier > 10
				item_description = 'Master '
			elsif stat_modifier > 6
				item_description = 'Superior '
			elsif stat_modifier > 2
				item_description = 'Great '
			end
			self.name ||= "#{item_description}#{item_type} of #{self.stat_modified.gsub('_rating', '').capitalize} +#{self.stat_modifier}"
		end
	end

	def item_type
		return 'Resource' if resource
		return race if humanoid || undead || elemental
		return 'Beast' if beast
		return 'Armour' if armour
		return 'Weapon' if weapon 
		return 'Vehicle' if vehicle
		return 'Siege Equipment' if siege_equipment
		return 'Trade Good' if trade_good
		return 'Magical' if magical
		'Unknown'
	end

	def to_s
		"#{name}"
	end

	def item_icon
		if magical
			return magical_type.downcase
		else
			return name.gsub(' ','_').downcase
		end
	end

	def range_description
		Combat::RANGE_NAME[self.range]
	end

	def raw_materials_description
		d = []
		d << "#{self.hide} #{'hide'.pluralize(self.hide)}" if self.hide > 0
		d << "#{self.iron} iron" if self.iron > 0
		d << "#{self.wood} wood" if self.wood > 0
		d << "#{self.stone} stone" if self.stone > 0
		d.join(', ')
	end

	def as_json(options={})
		{
			id: id,
			name: name,
			icon: item_icon,
			type: item_type,
			stat_modifier: stat_modifier,
			stat_modified: stat_modified,
			land_transport_capacity: land_transport_capacity,
			sea_transport_capacity: sea_transport_capacity,
			air_transport_capacity: air_transport_capacity
		}
	end
end
