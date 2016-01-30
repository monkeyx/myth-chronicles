class Hex < ActiveRecord::Base
	include Terrain
	include Spatial

	belongs_to :territory, class_name: 'Settlement'
	
	scope :owned, -> { where("territory_id > 0")}
	scope :unowned, -> { where("territory_id = 0")}
	scope :territory_of, ->(settlement) { where(territory_id: settlement.id )}
	
	def self.claim_territory!(game_id, x, y, settlement_id, radius)
		Hex.where(game_id: game_id).around_block(x,y,radius).update_all({:territory_id => settlement_id})
	end

	def to_s
		"#{location_id}"
	end

	def armies
		@armies ||= Army.at_loc(self.location).in_game(self.game)
	end

	def settlement
		@settlement ||= Settlement.at_loc(self.location).in_game(self.game).not_guilds.first
	end

	def city
		settlement && settlement.city? ? settlement : nil 
	end

	def tower
		settlement && settlement.tower? ? settlement : nil 
	end

	def lair 
		settlement && settlement.lair? ? settlement : nil 
	end

	def dungeon
		@dungeon ||= Dungeon.at_loc(self.location).in_game(self.game).first
	end

	def territory_colour
		return nil unless territory 
		territory.colour
	end

	def as_json(options={})
		{
			id: location_id,
			x: x,
			y: y,
			terrain: terrain.downcase,
			terrain_display: terrain.pluralize,
			armies: armies.map {|a| 
				{
					id: a.id,
					name: a.name
				}
			},
			city: city ? {id: city.id, name: city.name} : nil,
			tower: tower ? {id: tower.id, name: tower.name} : nil,
			lair: lair ? {id: lair.id, name: lair.name} : nil,
			dungeon: dungeon,
			territory: {
				id: territory_id,
				name: (territory ? territory.name : nil),
				colour: territory_colour
			}
		}
	end
end
