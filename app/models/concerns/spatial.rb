module Spatial
	extend ActiveSupport::Concern

	NEIGHBOURS = [[1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]]

	NORTH = 'North'
	NORTH_EAST = 'North-East'
	SOUTH_EAST = 'South-East'
	SOUTH = 'South'
	SOUTH_WEST = 'South-West'
	NORTH_WEST = 'North-West'

	DIRECTIONS = {
		NORTH_EAST => NEIGHBOURS[0],
		SOUTH_EAST => NEIGHBOURS[1],
		SOUTH => NEIGHBOURS[2],
		SOUTH_WEST => NEIGHBOURS[3],
		NORTH_WEST => NEIGHBOURS[4],
		NORTH => NEIGHBOURS[5]
	}

	DIRECTION_NAMES = [NORTH, NORTH_EAST, SOUTH_EAST, SOUTH, SOUTH_WEST, NORTH_WEST]


	class Location 
		attr_accessor :game, :x, :y 

		def self.direction(name)
			Location.new(nil, DIRECTIONS[name][0], DIRECTIONS[name][1])
		end

		def initialize(game=nil, x=nil, y=nil)
			self.game = game 
			self.x = x 
			self.y = y
		end

		def copy
			Location.new(self.game, self.x, self.y)
		end

		def ==(other)
			return false if other.nil? || !(other.respond_to?(:x) && other.respond_to?(:y))
			return false if self.game && other.game && self.game.id != other.game.id 
			self.x == other.x && self.y == other.y
		end

		def !=(other)
			!(self == other)
		end

		def +(other)
			raise "Invalid operation" if other.nil? || !(other.respond_to?(:x) && other.respond_to?(:y))
			Location.new(self.game, self.x + other.x, self.y + other.y)
		end

		def -(other)
			raise "Invalid operation" if other.nil? || !(other.respond_to?(:x) && other.respond_to?(:y))
			Location.new(self.game, self.x - other.x, self.y - other.y)
		end

		def *(other)
			raise "Invalid operation" if other.nil? || !(other.respond_to?(:x) && other.respond_to?(:y))
			Location.new(self.game, self.x * other.x, self.y * other.y)
		end

		def from_cube(x, y, z)
			self.x = x
			self.y = z
		end

		def to_cube
			s = 0 - self.x - self.y
			return x,y,s
		end

		def length
			q, r, s = to_cube 
			(q.abs + r.abs + s.abs / 2).round
		end

		def distance(other)
			raise "Invalid operation" if other.nil? || !(other.respond_to?(:x) && other.respond_to?(:y))
			(self - other).length
		end

		def adjacent?(other)
			distance(other) == 1
		end

		def neighbour(direction_name)
			self + Location.direction(direction_name)
		end

		def range(r)
			results = []
			(-r..r).each do |dX|
				min_dY = -r > (-dX -r) ? -r : (-dX -r)
				max_dY = r < (-dX + r) ? r : (-dX + r)
				(min_dY..max_dY).each do |dY|
					dZ = -dX -dY 
					loc = Location.new(self.game)
					loc.from_cube(dX, dY, dZ)
					results << (self + loc)
				end
			end
			results
		end

		def location
			copy
		end

		def id
			"(#{x}, #{y})"
		end

		def to_s
			"#{id}"
		end

		def as_json(options={})
			{
				x: x,
				y: y
			}
		end
	end

	included do
		validates :x, numericality: {only_integer: true, greater_than_or_equal_to: 0}
		validates :y, numericality: {only_integer: true, greater_than_or_equal_to: 0}
		belongs_to :game

		before_validation :set_location_id

		scope :at, ->(x,y) { where({x: x, y: y})}
		scope :at_loc, ->(loc) { at(loc.x, loc.y)}
		scope :at_id, ->(loc_id) { where(["location_id LIKE ?", "%#{loc_id.gsub(', ', ',').gsub(',', ', ')}%"])}
		scope :in_game, ->(game) { where({game_id: game.id })}

		def self.around_block(x, y, range)
			loc = Spatial::Location.new(nil, x, y)
			where(["location_id IN (?)", loc.range(range).map{|l| l.id }])
		end

		def self.around(location)
			around_block(location.x, location.y, 1)
		end
	end

	def location 
		Spatial::Location.new(self.game, self.x, self.y)
	end

	def location=(loc)
		raise "Invalid location type" unless loc.respond_to?(:x) && loc.respond_to?(:y) && loc.respond_to?(:game)
		self.x = loc.x 
		self.y = loc.y
		self.game = loc.game
	end

	def distance(other)
		location.distance(other)
	end

	def move(direction_name)
		self.location = self.location + Location.direction(direction_name)
	end

	def hex
		return self if is_a?(Hex)
		Hex.at(self.x, self.y).first
	end

	def terrain
		return read_attribute(:terrain) if is_a?(Hex)
		hex = hex
		hex.nil? ? nil : hex.read_attribute(:terrain)
	end

	def set_location_id
		self.location_id = location.id
	end
end