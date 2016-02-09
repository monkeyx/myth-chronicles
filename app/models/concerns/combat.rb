module Combat
	extend ActiveSupport::Concern

	BATTLE_TYPES = ['Army','Challenge']
	RANGE_NAME = ['Melee', 'Short', 'Long']

	def self.simulator!(max=100, generate_armies=true)
		Character.all.each do |c|
			(1..10).each do
				Army.create_random!(c)
				print '#'
			end
		end if generate_armies
		puts
		n = 0
		while n < max && (armies = Army.not_empty.no_characters).count > 1 do 
			a1 = armies.sample
			a2 = armies.sample
			unless a1.friendly?(a2)
				print '.'
				a1.units.each{|u| u.update_attributes(health: 100) }
				a2.units.each{|u| u.update_attributes(health: 100) }
				a1.location = a2.location
				a1.save!
				a1.fight! a2
				n += 1
			else

			end
		end
		puts
	end

	class CombatEngine
		attr_accessor :attacking_units, :defending_units, :location, 
			:rounds, :routed_units, :destroyed_units, :characters,
			:attacker_units_destroyed, :defender_units_destroyed,
			:attacker_units_table, :defender_units_table 

		def initialize(attacking_units, defending_units, location)
			self.attacking_units = attacking_units
			self.defending_units = defending_units
			self.attacker_units_table = {}
			attacking_units.each{|u| self.attacker_units_table[u] = {destroyed: false, routed: false, round: nil} }
			self.defender_units_table = {}
			defending_units.each{|u| self.defender_units_table[u] = {destroyed: false, routed: false, round: nil} }
			self.attacker_units_destroyed = 0
			self.defender_units_destroyed = 0
			self.routed_units = []
			self.destroyed_units = []
			self.location = location
			self.rounds = []
			self.characters = []
		end

		def fight!
			range = 0
			self.attacking_units.each{|unit| range = unit.adjusted_range if unit.adjusted_range > range; self.characters << unit.character if unit.character }
			self.defending_units.each{|unit| range = unit.adjusted_range if unit.adjusted_range > range; self.characters << unit.character if unit.character }

			self.characters.each do |c|
				c.update_attributes(experience_points: c.experience_points + 1)
			end

			round_number = 1
			(-range..0).each do |r|
				if r == 0
					n = 1
					while self.attacking_units.length > 0 && self.defending_units.length > 0 do 
						round = fight_round!(sorted_units, r, round_number)
						self.attacking_units = check_morale_and_deaths(self.attacking_units, round, round_number)
						self.defending_units = check_morale_and_deaths(self.defending_units, round, round_number)
						unless round.empty?
							round.unshift(I18n.translate("combat.round.melee", {round: n}))
							self.rounds << round 
							round_number += 1
							n += 1
						end
					end
				else
					round = fight_round!(sorted_units(r.abs), r, round_number)
					unless round.empty?
						if r.abs == 2
							round.unshift(I18n.translate("combat.round.long"))
						elsif r.abs == 1
							round.unshift(I18n.translate("combat.round.short"))
						end
						self.rounds << round 
						round_number += 1
					end
				end
			end
			self.rounds
		end

		def attacker_won?
			self.attacking_units.length > 0
		end

		def defender_won?
			self.defending_units.length > 0
		end

		private

		def fight_round!(units,range,round_number)
			round = []
			units.each do |unit|
				target = nil
				if attacker?(unit)
					target = pick_target(self.defending_units)
				else
					target = pick_target(self.attacking_units)
				end
				if target
					attack = attack_score(unit, target,range)
					defend = defend_score(target, unit,range)
					tactic_desc = tactical_description(unit, target)
					round << tactic_desc if tactic_desc
					if attack >= (3 * defend) # annihilated
						target.health = 0
						target.save
						round << I18n.translate('combat.unit.annihilated', {attacker: unit, defender: target, attacker_army: army_symbol(unit), defender_army: army_symbol(target)})
					elsif attack >= (2 * defend) # critical wounded
						damage = (rand(25) + 26)
						damage  = (damage * 0.5).round if target.evasive? && range > 0
						target.health -= damage
						target.save
						unless target.health < 1
							round << I18n.translate('combat.unit.critical', {attacker: unit, defender: target, damage: damage, attacker_army: army_symbol(unit), defender_army: army_symbol(target)})
						else
							round << I18n.translate('combat.unit.annihilated', {attacker: unit, defender: target, attacker_army: army_symbol(unit), defender_army: army_symbol(target)})
						end
					elsif attack >= defend # severe wounded
						damage = (rand(15) + 11)
						damage  = (damage * 0.5).round if target.evasive? && range > 0
						target.health -= damage
						target.save
						unless target.health < 1
							round << I18n.translate('combat.unit.severe', {attacker: unit, defender: target, damage: damage, attacker_army: army_symbol(unit), defender_army: army_symbol(target)})
						else
							round << I18n.translate('combat.unit.annihilated', {attacker: unit, defender: target, attacker_army: army_symbol(unit), defender_army: army_symbol(target)})
						end
					elsif attack >= (defend / 2.0) # wounded
						damage = (rand(6)) + 1
						damage  = (damage * 0.5).round if target.evasive? && range > 0
						target.health -= damage
						target.save
						unless target.health < 1
							round << I18n.translate('combat.unit.wounded', {attacker: unit, defender: target, damage: damage, attacker_army: army_symbol(unit), defender_army: army_symbol(target)})
						else
							round << I18n.translate('combat.unit.annihilated', {attacker: unit, defender: target, attacker_army: army_symbol(unit), defender_army: army_symbol(target)})
						end
					else # no damage
						round << I18n.translate('combat.unit.failed', {attacker: unit, defender: target, attacker_army: army_symbol(unit), defender_army: army_symbol(target)})
					end
					if unit.bless_rating > 0
						unit.update_attributes(bless_rating: 0)
						round << I18n.translate('combat.unit.bless_expired', {unit: unit, unit_army: army_symbol(unit)})
					end
				end
			end
			round
		end

		def check_morale_and_deaths(units, round, round_number)
			destroyed = []
			routed = []
			units.each do |unit|
				if unit.health < 1
					unit.destroy 
					if attacker?(unit)
						self.attacker_units_table[unit][:destroyed] = true
						self.attacker_units_table[unit][:round] = round_number
						self.attacker_units_destroyed += 1
					else
						self.defender_units_table[unit][:destroyed] = true
						self.defender_units_table[unit][:round] = round_number
						self.defender_units_destroyed += 1
					end
					if unit.character
						unless unit.character.incapacitated!
							unit.character.die!('in combat')
						end
					end
					destroyed << unit 
				elsif unit.undead? # no morale check
				elsif unit.stubborn? && unit.health > 75 # no morale check
				elsif unit.health < 100 || terrified?(unit)
					difficulty = 7
					if unit.health > 75
						difficulty += 3
					elsif unit.health > 50
						difficulty += 9
					elsif unit.health > 25
						difficulty += 15
					else
						difficulty += 21
					end
					n = 1 + rand(6) + (unit.army.owner ? unit.army.owner.leadership_rating : 0) + unit.adjusted_morale_rating + unit.bless_rating
					if n < difficulty
						if attacker?(unit)
							self.attacker_units_table[unit][:routed] = true
							self.attacker_units_table[unit][:round] = round_number
						else
							self.defender_units_table[unit][:routed] = true
							self.defender_units_table[unit][:round] = round_number
						end
						round << I18n.translate('combat.unit.routed', {unit: unit, unit_army: army_symbol(unit)})
						routed << unit
					end
				end
			end
			self.destroyed_units = self.destroyed_units + destroyed
			self.routed_units = self.routed_units + routed
			units.select{|unit| !(destroyed.include?(unit) || routed.include?(unit))}
		end

		def army_symbol(unit)
			if attacker?(unit)
				return 'A'
			else
				return 'D'
			end
		end

		def attacker?(unit)
			self.attacking_units.include?(unit)
		end

		def defender?(unit)
			self.defending_units.include?(unit)
		end

		def terrified?(unit)
			if attacker?(unit)
				self.defending_units.any?{|unit| unit.terrifying? }
			else
				self.attacking_units.any?{|unit| unit.terrifying? }
			end
		end

		def attack_score(unit, defender,range)
			health_rating = unit.indomitable? ? 100 : unit.health
			tactical = tactical_mod_attacking(unit, defender)
			(unit.bless_rating + unit.adjusted_strength_rating + rand(6) + 1 - (range == 0 ? unit.adjusted_range : 0)) * health_rating * tactical
		end

		def defend_score(unit, attacker,range)
			health_rating = unit.indomitable? ? 100 : unit.health
			tactical = tactical_mod_defending(unit, attacker)
			settlement = unit.army.at_friendly_settlement?
			fortification = settlement ? settlement.defence_rating : 0
			siege_equipment = attacker.siege_equipment ? attacker.siege_equipment.siege_effectiveness : 0
			siege_equipment = fortification if siege_equipment > fortification
			terrain = defender?(unit) && unit.army.defensive? ? 2 : 1
			(unit.bless_rating + unit.adjusted_armour_rating + rand(6) + 1 + fortification - siege_equipment) * health_rating * tactical * terrain
		end

		def tactical_description(attacker, defender)
			case attacker.tactic
				when 'Ambush'
					return I18n.translate('combat.tactic.ambush', {attacker: attacker, defender: defender, attacker_army: army_symbol(attacker), defender_army: army_symbol(defender)})
				when 'Flank'
					return I18n.translate('combat.tactic.flank', {attacker: attacker, defender: defender, attacker_army: army_symbol(attacker), defender_army: army_symbol(defender)})
				when 'Skirmish'
					if defender.tactic == 'Skirmish'
						return I18n.translate('combat.tactic.skirmish-skirmish', {attacker: attacker, defender: defender, attacker_army: army_symbol(attacker), defender_army: army_symbol(defender)})
					elsif defender.tactic == 'Wall'
						return I18n.translate('combat.tactic.skirmish-wall', {attacker: attacker, defender: defender, attacker_army: army_symbol(attacker), defender_army: army_symbol(defender)})
					else
						#return nil
						return I18n.translate('combat.tactic.skirmish', {attacker: attacker, defender: defender, attacker_army: army_symbol(attacker), defender_army: army_symbol(defender)})
					end
				when 'Swarm'
					if defender.tactic == 'Skirmish'
						return I18n.translate('combat.tactic.swarm-skirmish', {attacker: attacker, defender: defender, attacker_army: army_symbol(attacker), defender_army: army_symbol(defender)})
					elsif defender.tactic == 'Wall'
						return I18n.translate('combat.tactic.swarm-wall', {attacker: attacker, defender: defender, attacker_army: army_symbol(attacker), defender_army: army_symbol(defender)})
					else
						return nil
					end
				when 'Wall'
					if defender.tactic == 'Wall'
						return I18n.translate('combat.tactic.wall-skirmish', {attacker: attacker, defender: defender, attacker_army: army_symbol(attacker), defender_army: army_symbol(defender)})
					else
						return I18n.translate('combat.tactic.wall', {attacker: attacker, defender: defender, attacker_army: army_symbol(attacker), defender_army: army_symbol(defender)})
					end
			end
		end

		def tactical_mod_defending(unit, attacker)
			case unit.tactic
			when 'Ambush'
				return 1
			when 'Flank'
				return 1
			when 'Skirmish'
				if unit.army.difficult?
					if ['Skirmish', 'Swarm', 'Wall'].include?(attacker.tactic)
						return 2
					else
						return 1
					end
				else
					return 1
				end
			when 'Swarm'
				return 1
			when 'Wall'
				if ['Skirmish', 'Swarm'].include?(attacker.tactic)
					return 2
				else
					return 1
				end
			end
		end

		def tactical_mod_attacking(unit, defender)
			case unit.tactic
			when 'Ambush'
				if unit.army.difficult?
					if ['Flank', 'Swarm', 'Wall'].include?(defender.tactic)
						return 2
					else
						return 1
					end
				else
					return 1
				end
			when 'Flank'
				if !unit.army.difficult?
					if ['Skirmish', 'Swarm', 'Wall'].include?(defender.tactic)
						return 2
					else
						return 1
					end
				else
					return 1
				end
			when 'Skirmish'
				if unit.army.difficult?
					if ['Flank', 'Swarm', 'Wall'].include?(defender.tactic)
						return 2
					else
						return 1
					end
				else
					return 1
				end
			when 'Swarm'
				return 1
			when 'Wall'
				return 1
			end
		end

		def pick_target(units)
			return nil unless units.length > 0
			units = units.select{|u| u.health > 0 }
			units = units.sort{|a,b| a.adjusted_speed_rating <=> b.adjusted_speed_rating}
			return nil unless units.length > 0
			n = units[0].adjusted_speed_rating
			units = units.select{|unit| unit.adjusted_speed_rating == n}
			unless units.length == 1
				units = units.sort{|a,b| b.health <=> a.health }
				n = units[0].health
				units = units.select{|unit| unit.health == n}
				unless units.length == 1
					units = units.sort{|a,b| b.adjusted_armour_rating <=> a.adjusted_armour_rating }
					n = units[0].adjusted_armour_rating
					units = units.select{|unit| unit.adjusted_armour_rating == n}
					unless units.length == 1
						units = units.sort{|a,b| b.adjusted_strength_rating <=> a.adjusted_strength_rating }
						n = units[0].adjusted_strength_rating
						units = units.select{|unit| unit.adjusted_strength_rating == n}
					end
				end
			end
			units.sample
		end

		def sorted_units(range=0)
			(self.attacking_units.select{|unit| unit.range >= range} + self.defending_units.select{|unit| unit.adjusted_range >= range}).sort{|a, b| b.adjusted_speed_rating <=> a.adjusted_speed_rating }
		end
	end

	def fight!(other_position)
		raise "Invalid position" unless self.class == other_position.class || self.id == other_position.id || self.friendly?(other_position)
		raise "Invalid location" unless self.location == other_position.location
		attacker = nil
		defender = nil
		battle_type = nil
		unless is_a?(Character)
			battle_type = 'Army'
			engine = CombatEngine.new(self.units.order('speed_rating DESC').to_a, other_position.units.order('speed_rating DESC').to_a, location)
		else
			battle_type = 'Challenge'
			engine = CombatEngine.new([self.unit], [other_position.unit], location)
		end
		transaction do
			engine.fight!

			summary = engine.rounds.map{|r| r.join("<li>\n")}.join("<li>\n").chomp("<li>\n")
			summary = I18n.translate('combat.nothing', {attacker_army: self, defender_army: other_position}) if summary.blank?
			summary = "<li>\n" + summary

			attacker_units_table = engine.attacker_units_table.keys.map do |unit|
				status_desc = ''
				css_class = '' 
				if engine.attacker_units_table[unit][:destroyed]
					status_desc = " &nbsp; <span class=\"note\">Destroyed round #{engine.attacker_units_table[unit][:round]}</span>"
					css_class = 'destroyed'
				end
				if engine.attacker_units_table[unit][:routed]
					status_desc = " &nbsp; <span class=\"note\">Routed round #{engine.attacker_units_table[unit][:round]}</span>"
					css_class = 'routed'
				end
				"<tr><td><span class=\"#{css_class}\">#{unit}#{status_desc}</span></td><td>#{unit.tactic}</td><td>#{unit.health < 0 ? 0 : unit.health}%</td></tr>"
			end.join("\n")

			defender_units_table = engine.defender_units_table.keys.map do |unit|
				status_desc = ''
				css_class = '' 
				if engine.defender_units_table[unit][:destroyed]
					status_desc = " &nbsp; <span class=\"note\">Destroyed round #{engine.defender_units_table[unit][:round]}</span>"
					css_class = 'destroyed'
				end
				if engine.defender_units_table[unit][:routed]
					status_desc = " &nbsp; <span class=\"note\">Routed round #{engine.defender_units_table[unit][:round]}</span>"
					css_class = 'routed'
				end
				"<tr><td><span class=\"#{css_class}\">#{unit}#{status_desc}</span></td><td>#{unit.tactic}</td><td>#{unit.health < 0 ? 0 : unit.health}%</td></tr>"
			end.join("\n")

			br = BattleReport.create!(attacker: self.position, defender: other_position.position, battle_type: battle_type, 
				attacker_won: engine.attacker_won?, defender_won: engine.defender_won?, 
				attacker_units_destroyed: engine.attacker_units_destroyed, defender_units_destroyed: engine.defender_units_destroyed,
				attacker_units_table: attacker_units_table, defender_units_table: defender_units_table,
				summary: summary, game_time: game.game_time, location: location)

			br.update_attributes(summary: br.summary + "<li>\n<strong>#{br.winner}</strong>")
			
			if is_a?(Army)
				if self.unit_count < 1
					ActionReport.add_report!(self.owner, 'Army Disbanded', I18n.translate("cycles.army.disbanded", {army: self}), self) if self.owner
					self.destroy
				end

				if other_position.unit_count < 1
					ActionReport.add_report!(other_position.owner, 'Army Disbanded', I18n.translate("cycles.army.disbanded", {army: other_position}), self) if other_position.owner
					other_position.destroy
				end

				if engine.attacker_won?
					unless other_position.destroyed?
						other_position.flee!
					end
					if self.owner
						gold = 0
						(1..engine.defender_units_table.count).each{ gold += rand(6) + 1}
						self.owner.add_gold!(gold) 
						ActionReport.add_report!(self.owner, 'Loot', I18n.translate("combat.loot", {army: other_position, gold: gold, location: location}), self)
					end
				else
					unless self.destroyed?
						self.flee!
					end
					if other_position.owner
						gold = 0
						(1..engine.attacker_units_table.count).each{ gold += rand(6) + 1}
						other_position.owner.add_gold!(gold) 
						ActionReport.add_report!(other_position.owner, 'Loot', I18n.translate("combat.loot", {army: self, gold: gold, location: location}), other_position)
					end
				end
			end

			br
		end
	end
end