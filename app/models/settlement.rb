class Settlement < ActiveRecord::Base
	SETTLEMENT_TYPES = ['Guild', 'City', 'Tower', 'Lair']

	STARTING_LAIR_TERRAIN = ['Desert','Sea']

	STARTING_CITY_TERRAIN = ['Plains','Forest','Hill','Barren','Scrubland','Wasteland']

	STARTING_TOWER_TERRAIN = ['Plains','Forest']

	VALID_CITY_TERRAIN = ['Plains', 'Forest', 'Hill', 'Barren', 'Scrubland', 'Wasteland', 'Mountain']

	VALID_LAIR_TERRAIN = ['Desert', 'Sea', 'Mountain']

	VALID_TOWER_TERRAIN = ['Plains', 'Forest', 'Mountain']

	FORM_GOLD_COST = {
		'Guild' => 1000,
		'City' => 0,
		'Tower' => 0,
		'Lair' => 0
	}

	FORM_WOOD_COST = {
		'Guild' => 0,
		'City' => 500,
		'Tower' => 0,
		'Lair' => 0
	}

	FORM_STONE_COST = {
		'Guild' => 500,
		'City' => 500,
		'Tower' => 500,
		'Lair' => 0
	}

	FORM_MANA_COST = {
		'Guild' => 0,
		'City' => 0,
		'Tower' => 100,
		'Lair' => 200
	}

	FORM_CITY_MINIMUM_HUMANOIDS = 10

	IMPROVE_DEFENCES_COST_MULTIPLIER = 50

	SIZE_HAMLET = 10
	SIZE_VILLAGE = 100
	SIZE_TOWN = 1000
	SIZE_CAPITAL = 10000

	LOYALTY_BOOST_FOR_TRADE_GOODS = 10
	LOYALTY_LOSS_FOR_TAXATION = 5

	include Races
	include PositionType

	validates :settlement_type, inclusion: {in: SETTLEMENT_TYPES}
	validates :population_race, inclusion: {in: [''] + HUMANOIDS }
	validates :population_size, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :population_loyalty, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :year_last_taxed, numericality: {only_integer: true, greater_than_or_equal_to: 0}

	belongs_to :city, class_name: 'Settlement'
	has_one :guild, class_name: 'Settlement', foreign_key: 'city_id'

	validates :defence_rating, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	# under_siege

	has_many :settlement_permissions, dependent: :delete_all
	has_many :territories, class_name: 'Hex', foreign_key: 'territory_id', dependent: :nullify

	scope :of_type, ->(settlement_type) { where(settlement_type: settlement_type) }

	SETTLEMENT_TYPES.each do |settlement_type|
		define_method("#{settlement_type.downcase}?") do 
			self.settlement_type == settlement_type
		end

		scope settlement_type.downcase.to_sym, -> { where(settlement_type: settlement_type)}
		scope "not_#{settlement_type.pluralize.downcase}".to_sym, -> { where(["settlement_type <> ?", settlement_type])}
	end

	scope :hamlets, -> { where(["population_size >= ?", SIZE_HAMLET])}
	scope :villages, -> { where(["population_size >= ?", SIZE_VILLAGE])}
	scope :towns, -> { where(["population_size >= ?", SIZE_TOWN])}
	scope :capitals, -> { where(["population_size >= ?", SIZE_CAPITAL])}

	after_destroy :create_dungeon!

	def self.create_guild!(city, name="Guild", owner=nil)
		pos = Position.create_settlement!(city.game, owner, 'Guild', city.location, name)
		pos.update_attributes!(defence_rating: 0, city: city)
		pos
	end

	def self.create_city!(game, location, name, race, size, owner=nil)
		pos = Position.create_settlement!(game, owner, 'City', location, name)
		pos.update_attributes!(defence_rating: 2, population_race: race, population_size: size, population_loyalty: 100)
		Hex.claim_territory!(pos.game.id, pos.x, pos.y, pos.id, pos.territory_radius)
		pos
	end

	def self.create_lair!(game, location, name="Lair", owner=nil)
		pos = Position.create_settlement!(game, owner, 'Lair', location, name)
		pos.update_attributes!(defence_rating: 0)
		Hex.claim_territory!(pos.game.id, pos.x, pos.y, pos.id, pos.territory_radius)
		pos
	end

	def self.create_tower!(game, location, name="Tower", owner=nil)
		pos = Position.create_settlement!(game, owner, 'Tower', location, name)
		pos.update_attributes!(defence_rating: 1)
		Hex.claim_territory!(pos.game.id, pos.x, pos.y, pos.id, pos.territory_radius)
		pos
	end

	def allowed_owner_type?(character_type)
		Character::CHARACTER_SETTLEMENT_TYPE[character_type] == self.settlement_type
	end

	def subtype
		self.settlement_type
	end

	def race
		self.population_race
	end

	def size_description
		return "Hamlet" if hamlet?
		return "Village" if village?
		return "Town" if town?
		return "Capital" if capital?
	end

	def hamlet?
		self.population_size < SIZE_VILLAGE
	end

	def village?
		self.population_size >= SIZE_VILLAGE && self.population_size < SIZE_TOWN
	end

	def town?
		self.population_size >= SIZE_TOWN && self.population_size < SIZE_CAPITAL
	end

	def capital?
		self.population_size >= SIZE_CAPITAL
	end

	def territory_radius
		if guild?
			return 0
		elsif city?
			if hamlet?
				return 0
			elsif village?
				return 1
			elsif town?
				return 2
			elsif capital?
				return 3
			end
		elsif tower?
			return 1
		elsif lair?
			return 4
		end
	end

	#
	# Recruitment
	#
	def recruitment_rate
		return 0 if recruitment_race_item.nil?
		
		if recruitment_race_item.beast?
			return 10
		elsif recruitment_race_item.frisky?
			return 100 * production_rate
		elsif recruitment_race_item.rare?
			return 1 * production_rate
		else
			return 10 * production_rate
		end
	end

	def recruitment_race_item
		if city?
			Item.of_terrain(self.terrain).humanoid.first
		elsif tower?
			Item.of_terrain(self.terrain).undead.first
		elsif lair?
			Item.of_terrain(self.terrain).elemental.first
		elsif guild?
			Item.of_terrain(self.terrain).beast.first
		end
	end

	def recruit!
		add_items!(recruitment_race_item, recruitment_rate)
		return recruitment_rate
	end

	#
	# City Resource Production
	#
	def production_rate
		return 1 unless city?
		return 1 if hamlet?
		return 2 if village?
		return 5 if town?
		return 10 if capital?
		0
	end

	def hides_produced
		Hex.in_game(self.game).territory_of(self).any_of_terrains(Terrain::HIDE_TERRAIN.keys).to_a.sum do |h|
			Terrain::HIDE_TERRAIN[h.terrain] * production_rate
		end.round
	end

	def wood_produced
		Hex.in_game(self.game).territory_of(self).any_of_terrains(Terrain::WOOD_TERRAIN.keys).to_a.sum do |h|
			Terrain::WOOD_TERRAIN[h.terrain] * production_rate
		end.round
	end

	def iron_produced
		Hex.in_game(self.game).territory_of(self).any_of_terrains(Terrain::IRON_TERRAIN.keys).to_a.sum do |h|
			Terrain::IRON_TERRAIN[h.terrain] * production_rate
		end.round
	end

	def stone_produced
		Hex.in_game(self.game).territory_of(self).any_of_terrains(Terrain::STONE_TERRAIN.keys).to_a.sum do |h|
			Terrain::STONE_TERRAIN[h.terrain] * production_rate
		end.round
	end

	def total_resource_produced
		hides_produced + wood_produced + iron_produced + stone_produced
	end

	def produce_resources!
		return unless city?
		hides = hides_produced
		wood = wood_produced
		iron = iron_produced
		stone = stone_produced
		add_items!('Hide', hides) if hides > 0
		add_items!('Wood', wood) if wood > 0
		add_items!('Iron', iron) if iron > 0
		add_items!('Stone', stone) if stone > 0
		{hides: hides, wood: wood, iron: iron, stone: stone}
	end

	#
	# Permissions
	#

	def full_permission?(position)
		return false unless position
		return true if position.owner.id == self.owner.id
		SettlementPermission.for_settlement(self).for_position(position).full.count > 0
	end

	def pickup_permission(position, item)
		return 0 unless position && item 
		sp = SettlementPermission.for_settlement(self).for_position(position).for_item(item).first
		sp.nil? ? 0 : sp.quantity
	end

	def give_full_permission!(position)
		return unless position
		return if position.owner.id == self.owner.id
		SettlementPermission.create!(position: position, settlement: self, full: true) unless full_permission?(position)
	end

	def give_pickup_permission!(position, item, quantity)
		return unless position && item
		return if position.owner.id == self.owner.id
		sp = SettlementPermission.for_settlement(self).for_position(position).for_item(item).first
		sp ||= SettlementPermission.new(position: position, settlement: self, item: item, quantity: 0)
		sp.quantity += quantity
		sp.save!
	end

	def use_pickup_permission!(position, item, quantity)
		return unless position && item
		return if position.owner.id == self.owner.id || full_permission?(position)
		sp = SettlementPermission.for_settlement(self).for_position(position).for_item(item).first
		raise "Invalid pickup" unless (sp && sp.quantity >= quantity)
		sp.quantity -= quantity
		sp.save!
	end

	#
	# Razing
	#

	def raze!(attacker)
		if attacker
			items.each do |pi|
				n = (50 + rand(50)) / 100.0
				quantity = (pi.quantity * n).round 
				attacker.add_items!(pi, quantity) if quantity > 0
			end
			if self.population_size > 0
				n = (50 + rand(50)) / 100.0
				quantity = (self.population_size * n).round
				race_item = Item.of_race(self.population_race).first
				attacker.add_items!(race_item, quantity)
			end 
		end
		ActionReport.add_report!(self.owner, "#{settlement_type} Razed", I18n.translate("combat.razed", {settlement: self, location: self.location, attacker: attacker}), self)
		destroy
	end

	def create_dungeon!
		unless (self.city? && (hamlet? || village?)) || Dungeon.in_game(self.game).at_loc(self.location).count > 0
			Dungeon.create_dungeon!(self.game, self.x, self.y, "Ruins of #{self.name}",rand(3) + 1)
		end
	end

	#
	# Cataclysm
	#
	def cataclysm!
		transaction do
			hexes = self.territories.to_a 
			if hexes.any?{|hex| hex.water? } # flooding
				self.hex.update_attributes(terrain: 'Swamp')
				hexes.each do |hex|
					unless hex.water? || hex.terrain == 'Mountain' || hex.terrain == 'Volcano'
						hex.update_attributes!(terrain: 'Sea')
					end
				end
				Rumour.report_disaster!(self.game.game_time, location, "Great flood sweeps region around ##{location}")
			elsif hexes.any?{|hex| hex.terrain == 'Mountain' || hex.terrain == 'Volcano'} # volcanic eruption
				self.hex.update_attributes(terrain: 'Volcano')
				hexes.each do |hex|
					unless hex.terrain == 'Mountain' || hex.terrain == 'Volcano'
						if hex.distance(self.hex) == 1
							hex.update_attributes(terrain: 'Hill')
						elsif hex.distance(self.hex) < 4 && hex.terrain == 'River'
							hex.update_attributes(terrain: 'Barren')
						elsif !hex.water?
							hex.update_attributes(terrain: 'Wasteland')
						end
					end
				end
				Rumour.report_disaster!(self.game.game_time, location, "A great volcanic eruption occurred at ##{location}")
			elsif hexes.any?{|hex| hex.terrain == 'Forest'} # wildfires
				self.hex.update_attributes(terrain: 'Desert')
				hexes.each do |hex|
					if hex.terrain == 'Forest' || hex.terrain == 'Scrubland'
						hex.update_attributes(terrain: 'Wasteland')
					elsif hex.terrain == 'Hill'
						hex.update_attributes(terrain: 'Barren')
					elsif hex.terrain == 'Plains'
						hex.update_attributes(terrain: 'Scrubland')
					end
				end
				Rumour.report_disaster!(self.game.game_time, location, "Life destroying wildfires spread from ##{location}")
			else # meteor strike
				self.hex.update_attributes(terrain: 'Barren')
				max_distance = hexes.map{|hex| self.hex.distance(hex)}.max
				hexes.each do |hex|
					if self.hex.distance(hex) == max_distance
						hex.update_attributes(terrain: 'Mountain')
					elsif
						hex.update_attributes(terrain: 'Barren')
					end
				end
				Rumour.report_disaster!(self.game.game_time, location, "A giant meteor struck at ##{location}")
			end
			destroy
		end
	end

	def as_json(options={})
		self.position.as_json(options.merge({full: true})).merge({
			race: population_race,
			size: "#{size_description} (#{population_size})",
			loyalty: population_loyalty,
			year_last_taxed: year_last_taxed,
			defence_rating: defence_rating,
			under_siege: under_siege,
			permission_granted: settlement_permissions.has_some,
			armies_present: Army.at_loc(location).map {|army| {id: army.id, name: army.name, owner: { id: army.owner.id, name: army.owner.name }}}
		})
	end
end
