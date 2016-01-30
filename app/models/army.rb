class Army < ActiveRecord::Base
	include PositionType
	include Combat

	MOVEMENT_ACTION_POINT_COST = 4
	
	validates :air_capacity, numericality: {only_integer: true}
	validates :land_capacity, numericality: {only_integer: true}
	validates :sea_capacity, numericality: {only_integer: true}
	validates :scouting, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :unit_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :character_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	# guarding
	belongs_to :sieging, class_name: 'Settlement'

	has_many :units

	after_create :calculate!
	after_save :set_location_for_characters!
	after_destroy :move_characters_out!

	scope :guarding, -> { where(guarding: true )}
	scope :empty, -> { where("unit_count = 0")}
	scope :not_empty, -> { where("unit_count > 0")}
	scope :no_characters, -> { where("character_count = 0")}
	scope :some_characters, -> { where("character_count > 0")}

	def self.create_random!(owner, location=owner.location)
		transaction do
			army = Position.create_army!(owner.game, owner, "#{owner.name}'s Army")
			n = rand(10) + 1
			(1..n).each do
				item = Item.of_race(Races::ALL_RACES.select{|r| !r.blank? && r != 'Character'}.sample).first
				unit = Unit.create_unit!(army, item)
				unless unit.elemental?
					armour = Item.armour.to_a.sample
					weapon = Item.weapon.to_a.sample
					unless armour.training_required.blank?
						unit.update_attributes(training: armour.training_required)
					end
					unit.equip!(armour) if unit.can_equip?(armour)
					unless weapon.training_required.blank? || !unit.training.blank?
						unit.update_attributes(training: weapon.training_required)
					end
					unit.equip!(weapon) if unit.can_equip?(weapon)

					unless unit.undead?
						mount = rand(10) > 5 ? Item.beast.to_a.sample : nil
						if mount
							unless mount.training_required.blank? || !unit.training.blank?
								unit.update_attributes(training: mount.training_required)
							end
							unit.equip!(mount) if unit.can_equip?(mount)
						end
					end
				end
				siege_equipment = !unit.mount && rand(10) > 5 ? Item.siege_equipment.to_a.sample : nil 
				unit.equip!(siege_equipment) if siege_equipment && unit.can_equip?(siege_equipment)
				unit.update_attributes!(training: Training::ALL_TRAINING.sample) if unit.training.blank? && rand(10) > 5
				tactic = unit.training.blank? ? 'Swarm' : Tactics::TACTIC_FOR_TRAINING[unit.training] || 'Swarm'
				unit.update_attributes!(tactic: tactic)
			end
			army.calculate!
		end
	end
	
	def subtype
		'Army'
	end

	def flee!
		hex = nil
		if movement_air?
			hex = Hex.in_game(self.game).around(self.location).to_a.sample
		elsif movement_land?
			hex = Hex.in_game(self.game).around(self.location).not_water.not_impassable.to_a.sample
		elsif movement_sea?
			hex = Hex.in_game(self.game).around(self.location).water.to_a.sample
		end
		if hex
			ActionReport.add_report!(self, 'Fled', I18n.translate("combat.fled", {army: self, location: self.location}), self)
			self.location = hex.location
			save!
		end
	end

	def besiege!(settlement)
		transaction do
			settlement.under_siege = true
			settlement.save!
			self.sieging = settlement
			save!
		end
	end

	def scout!(hex, report_to=self, scout_rank=self.scouting)
		armies = Army.in_game(self.game).at_loc(hex.location).where(["armies.id <> ?", self.id])
		armies.each do |army|
			scout_army!(army, report_to, report_to, scout_rank)
		end
		armies.count
	end

	def scout_army!(army, cause=self, report_to=self, scout_rank=self.scouting)
		units_scouted = []
		army.units.each do |unit|
			n = scout_rank + rand(6) + 1
			units_scouted << unit.to_s if n >= unit.visibility
		end
		unit_count = units_scouted.length > 0 ? "#{units_scouted.length} #{'unit'.pluralize(units_scouted.length)}" : 'no units'
		r = I18n.translate('scouting.report', {army: army, location: army.location, unit_count: unit_count})
		r = r + ":<br>\n" + units_scouted.join("<br>\n") if units_scouted.length > 0
		ActionReport.add_report!(report_to, 'Scout Report', r, cause)
	end

	def movement_air?
		self.air_capacity >= 0
	end

	def movement_sea?
		self.sea_capacity >= 0
	end

	def movement_land?
		self.land_capacity >= 0
	end

	def immobile?
		!(movement_air? || movement_land?)
	end

	def calculate!
		self.air_capacity = 0
		self.sea_capacity = 0
		self.land_capacity = 0
		self.scouting = 0
		self.unit_count = self.units.count
		self.character_count = 0
		
		self.units.each do |unit|
			if unit.adjusted_flying?
				self.air_capacity += 100
			else
				self.air_capacity -= 100
			end
			if unit.adjusted_swimming?
				self.sea_capacity += 100
			else
				self.sea_capacity -= 100
			end
			self.land_capacity += 100
			if unit.mount
				self.air_capacity += unit.mount.air_transport_capacity
				self.sea_capacity += unit.mount.sea_transport_capacity
				self.land_capacity += unit.mount.land_transport_capacity
			end
			if unit.transport 
				self.air_capacity += unit.transport.air_transport_capacity
				self.sea_capacity += unit.transport.sea_transport_capacity
				self.land_capacity += unit.transport.land_transport_capacity
			end
			if unit.siege_equipment 
				self.air_capacity += unit.siege_equipment.air_transport_capacity
				self.sea_capacity += unit.siege_equipment.sea_transport_capacity
				self.land_capacity += unit.siege_equipment.land_transport_capacity
			end
			self.scouting = unit.adjusted_scouting_rating if unit.adjusted_scouting_rating > self.scouting 
			self.character_count += 1 if unit.character
		end

		self.position.position_items.each do |pi|
			#raise "#{pi} - A: #{(pi.item.air_transport_capacity * pi.quantity)} / S: #{(pi.item.sea_transport_capacity * pi.quantity)} / L: #{(pi.item.land_transport_capacity * pi.quantity)}"
			self.air_capacity += (pi.item.air_transport_capacity * pi.quantity)
			self.sea_capacity += (pi.item.sea_transport_capacity * pi.quantity)
			self.land_capacity += (pi.item.land_transport_capacity * pi.quantity)
		end

		#raise "A: #{self.air_capacity} / S: #{self.sea_capacity} / L: #{self.land_capacity}" if self.position.position_items.count > 0

		save!
	end

	def set_location_for_characters!
		Unit.for_army(self).character.each do |unit|
			character = unit.character
			character.location = self.location 
			character.save!
			character.challenges_received.each {|challenge| challenge.reject! }
			character.challenges_given.each {|challenge| challenge.cancel! }
		end
	end

	def move_characters_out!
		Unit.for_army(self).character.each do |unit|
			character = unit.character
			if character
				army = Position.create_army!(self.game, character, "#{character} Army")
				unit.update_attributes!(army: army)
			end
		end
	end

	def as_json(options={})
		self.position.as_json(options.merge({full: true})).merge({
			air_capacity: air_capacity,
			sea_capacity: sea_capacity,
			land_capacity: land_capacity,
			movement_land: movement_land?,
			movement_air: movement_air?,
			movement_sea: movement_sea?,
			scouting: scouting,
			guarding: guarding,
			sieging: {
				id: sieging_id,
				name: (sieging ? sieging.name : nil)
			},
			units: units
		})
	end
end
