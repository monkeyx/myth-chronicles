class SetupGame
	require 'csv'  
	include Resque::Plugins::Status
	include NameArrays

	@city_name_index = 0
	@dungeon_name_index = 0
	
	SETTLEMENT_TYPES = ['City', 'City', 'Tower', 'Lair']
	BLOCK_SIZE = 169
	BLOCK_RADIUS = 6

	@queue = :setup

	attr_accessor :game

	def self.schedule(game)
		create(id: game.id)
	end

	def self.setup!(game)
		Rails.logger.info "Setup Game: #{game}: START"
		game.transaction do 
			SetupGame.reset!(game)
			SetupGame.create_map!(game)
			SetupGame.create_neutral_settlements!(game)
			SetupGame.create_dungeons!(game)
			SetupGame.complete_setup!(game)
			(1..24).each do
				CycleGame.city_resource_generation!(game, true)
			end
		end
		Rails.logger.info "Setup Game: #{game}: FINISH"
	end

	def perform
		self.game = Game.where(id: options['id']).first
		if self.game
			begin
				SetupGame.setup!(self.game)
			rescue => e
				set_status(:error, e.to_s)
				Rails.logger.error "Setup Game: #{options['id']}: ERROR #{e}"
				Rails.logger.error e.backtrace
			end
		end
	end

	def self.complete_setup!(game)
		game.update_attributes!(setup_complete: true)
	end

	def self.reset!(game)
		Rails.logger.info "Setup Game: #{game}: RESET START"
		Hex.in_game(game).destroy_all
		Position.in_game(game).destroy_all
		Dungeon.in_game(game).destroy_all
		Rails.logger.info "Setup Game: #{game}: RESET FINISH"
	end

	def self.create_map!(game)
		Rails.logger.info "Setup Game: #{game}: CREATE MAP START"
		y = 0
		CSV.foreach("#{Rails.root}/public/maps/#{game.map_name}.csv") do |row|
			x = 0
			row.each do |terrain|
				Hex.create!(game: game, x: x, y: y, terrain: terrain)
				x += 1
			end
			y += 1
		end
		game.update_attributes!(map_size: (Hex.in_game(game).maximum(:x) + 1))
		Rails.logger.info "Setup Game: #{game}: CREATE MAP FINISH"
	end

	def self.create_neutral_settlements!(game)
		total_blocks = (game.map_size * game.map_size) / BLOCK_SIZE
		max = (game.map_size - 1)
		settlement_index = 0
		Rails.logger.info "Setup Game: #{game}: CREATE SETTLEMENTS START: Total Blocks = #{total_blocks} (radius: #{BLOCK_RADIUS}, max: #{max})"
		y = BLOCK_RADIUS
		until y > max do 
			x = BLOCK_RADIUS
			until x > max do 
				#Rails.logger.info "(#{x}, #{y})"
				case SETTLEMENT_TYPES[settlement_index]
				when 'Lair'
					create_lair!(game, x,y)
				when 'City'
					create_city!(game, x,y)
				when 'Tower'
					create_tower!(game, x,y)
				end
				settlement_index += 1
				if settlement_index >= SETTLEMENT_TYPES.length
					settlement_index = 0
				end
				x += (BLOCK_RADIUS * 2)
			end
			settlement_index += 1
			if settlement_index >= SETTLEMENT_TYPES.length
				settlement_index = 0
			end
			y += (BLOCK_RADIUS * 2)
		end
		Rails.logger.info "Setup Game: #{game}: CREATE SETTLEMENTS FINISH"
	end

	def self.create_lair!(game, x, y)
		Rails.logger.info "Setup Game: #{game}: CREATE LAIR (#{x},#{y})" # START"
		hex = Hex.in_game(game).around_block(x,y,BLOCK_RADIUS).unowned.any_of_terrains(Settlement::STARTING_LAIR_TERRAIN).order("RANDOM()").limit(1).first
		return if hex.nil?
		Settlement.create_lair!(game, hex.location)
		Dungeon.create_dungeon!(game, hex.x, hex.y, random_dungeon_name)
	end

	def self.create_city!(game, x, y)
		Rails.logger.info "Setup Game: #{game}: CREATE CITY (#{x},#{y})" # START"
		hex = Hex.in_game(game).around_block(x,y,BLOCK_RADIUS).unowned.any_of_terrains(Settlement::STARTING_CITY_TERRAIN).order("RANDOM()").select{|hex| !(Hex.in_game(game).around_block(hex.x,hex.y,2).any_of_terrains(Terrain::WOOD_TERRAIN.keys).count < 3 || Hex.in_game(game).around_block(hex.x,hex.y,2).any_of_terrains(Terrain::STONE_TERRAIN.keys).count < 3 || Hex.in_game(game).around_block(hex.x,hex.y,2).any_of_terrains(Terrain::HIDE_TERRAIN.keys).count < 1 || Hex.in_game(game).around_block(hex.x,hex.y,2).any_of_terrains(Terrain::IRON_TERRAIN.keys).count < 1)}.first
		return if hex.nil?
		city = Settlement.create_city!(game, hex.location, random_city_name, hex.terrain_city_recruitment, 1000)
		create_guild!(city)
	end

	def self.create_tower!(game, x, y)
		Rails.logger.info "Setup Game: #{game}: CREATE TOWER (#{x},#{y})" # START"
		hex = Hex.in_game(game).around_block(x,y,BLOCK_RADIUS).unowned.any_of_terrains(Settlement::STARTING_TOWER_TERRAIN).order("RANDOM()").limit(1).first
		return if hex.nil?
		Settlement.create_tower!(game, hex.location)
	end

	def self.create_guild!(city)
		return unless Terrain::BEAST_TERRAIN_TAMING.keys.include?(city.terrain)
		Rails.logger.info "Setup Game: #{city.game}: CREATE GUILD (#{city})" # START"
		Settlement.create_guild!(city)
	end

	def self.random_city_name
		name = CITY_NAMES[@city_name_index]
		@city_name_index += 1
		@city_name_index = 0 if @city_name_index >= CITY_NAMES.length
		name
	end

	def self.random_dungeon_name
		name = DUNGEON_NAMES[@dungeon_name_index]
		@dungeon_name_index += 1
		@dungeon_name_index = 0 if @dungeon_name_index >= DUNGEON_NAMES.length
		name
	end

	def self.create_dungeons!(game)
		Rails.logger.info "Setup Game: #{game}: CREATE DUNGEONS START"
		(1..20).each do |max_levels|
			total_dungeons_for_max_levels = (game.map_size * game.map_size) / (BLOCK_SIZE * max_levels * 2)
			(1..total_dungeons_for_max_levels).each do
				hex = nil 
				sanity = 5
				until !hex.nil? || sanity == 0 do 
					x = rand(game.map_size)
					y = rand(game.map_size)
					hex = Hex.in_game(game).around_block(x,y,BLOCK_RADIUS).unowned.limit(1).first
					hex = nil if hex && Dungeon.at_loc(hex.location).count > 0
					sanity -= 1
				end
				if hex 
					Dungeon.create_dungeon!(game, hex.x, hex.y, random_dungeon_name, max_levels)
				end
			end
		end
		Rails.logger.info "Setup Game: #{game}: CREATE DUNGEONS FINISH"
	end

end