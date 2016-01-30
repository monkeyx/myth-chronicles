class MapHex
	NEIGHBOURS = [[1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]]

	attr_accessor :x, :y, :elevation, :temperature, :rainfall, :terrain

	def initialize(values={})
		self.x = values.delete(:x)
		self.y = values.delete(:y)
		self.elevation = values.delete(:elevation)
		self.temperature = values.delete(:temperature)
		self.rainfall = values.delete(:rainfall) || 0
		self.terrain = values.delete(:terrain)
		self.terrain = 'Sea' if values.delete(:sea)
		self.terrain = 'Mountain' if values.delete(:mountain)
		self.terrain = 'Hill' if values.delete(:hill)
		self.terrain ||= 'Plains'
	end

	def mountain?
		self.terrain == 'Mountain'
	end

	def volcano?
		self.terrain == 'Volcano'
	end

	def sea?
		self.terrain == 'Sea'
	end

	def hill?
		self.terrain == 'Hill'
	end

	def river?
		self.terrain == 'River'
	end

	def symbol
		case self.terrain
		when 'Forest'
			return 'T'
		when 'Scrubland'
			return ''
		when 'Desert'
			return '.'
		when 'Barren'
			return ','
		when 'Swamp'
			return ';'
		when 'Wasteland'
			return '-'
		when 'Volcano'
			return 'V'
		when 'Mountain'
			return 'M'
		when 'Hill'
			return 'n'
		when 'Sea'
			return '~'
		when 'River'
			return '*'
		else
			return ' '
		end
	end

	def heat_symbol
		if self.temperature >= 40
			return 'O'
		elsif self.temperature >= 20
			return 'o'
		elsif self.temperature >= 0
			return ' '
		else
			return '*'
		end
	end

	def rain_symbol
		if self.rainfall > 3
			return '#'
		elsif self.rainfall > 2
			return 	'~'
		elsif self.rainfall > 1
			return '-'
		elsif self.rainfall > 0
			return '.'
		else
			return ' '
		end
	end

	def ==(other)
		self.x == other.x && self.y == other.y
	end

	def !=(other)
		!(self == other)
	end

	def +(other)
		MapHex.new({x: self.x + other.x, y: self.y + other.y})
	end

	def -(other)
		MapHex.new({x: self.x - other.x, y: self.y - other.y})
	end

	def *(other)
		MapHex.new({x: self.x * other.x, y: self.y * other.y})
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
		(self - other).length
	end

	def neighbours
		results = []
		NEIGHBOURS.each do |direction|
			results << (self + MapHex.new({x: direction[0], y: direction[1]}))
		end
		results
	end

	def range(r)
		results = []
		(-r..r).each do |dX|
			min_dY = -r > (-dX -r) ? -r : (-dX -r)
			max_dY = r < (-dX + r) ? r : (-dX + r)
			(min_dY..max_dY).each do |dY|
				dZ = -dX -dY 
				hex = MapHex.new
				hex.from_cube(dX, dY, dZ)
				results << (self + hex)
			end
		end
		results
	end

end

class MapGenerator

	RANGE = 128
	ROUGHNESS = 0.75

	MIN_SEA = 0.1
	MAX_SEA = 0.5
	MIN_MOUNTAIN = 0.1
	MAX_MOUNTAIN = 0.2
	MIN_HILLS = 0.1
	MAX_HILLS = 0.4
	AQUIFERS = 3

	attr_accessor :lengthExpo, :size, :rows, :attempts, :peaks, :rivers, :seas

	def self.bulk_generate!(lengthExpo, quantity, offset=1)
		quantity.times do |n|
			print "Generating map"
			g = MapGenerator.generate!(lengthExpo)
			g.save!("#{n + offset}")
		end
	end

	def self.generate!(lengthExpo)
		gen = MapGenerator.new(lengthExpo)
		gen.generate!
		gen
	end

	def initialize(lengthExpo)
		self.lengthExpo = lengthExpo 
		self.attempts = 0
		@wp = WeakPlasmoid.new
	end

	def generate!
		generate_land!
		generate_rivers!
		assign_moisture!
		determine_biomes!
		#print_map
		#print_heat_map
		#print_rainfall_map
	end

	def save!(name)
		data_rows = []
		File.open("#{Rails.root}/public/maps/#{name}.csv", 'w+') do |f|
			self.rows.each do |row|
				data_columns = []
				row.each do |hex|
					f.write(hex.terrain)
					f.write(',') unless row.last == hex
					data_columns << "'#{hex.terrain.downcase}'"
				end
				data_rows << "[#{data_columns.join(', ')}]"
				f.write("\n")
			end
			puts "Saved #{Rails.root}/public/maps/#{name}.csv"
		end
		center = (self.size / 2.0).round
		radius = self.size - center
		template = File.open("#{Rails.root}/public/maps/template.html", "rb").read
		template.gsub!('%%CENTER&&', center.to_s)
		template.gsub!('%%RADIUS%%', radius.to_s)
		template.gsub!('%%DATA%%', "[#{data_rows.join(',')}]")
		File.open("#{Rails.root}/public/maps/#{name}.html", 'w+') do |f|
			f.write(template)
			puts "Saved #{Rails.root}/public/maps/#{name}.html"
		end
		nil
	end

	def print_map
		puts
		self.rows.each do |row|
			row.each do |hex|
				print hex.symbol
			end
			puts
		end
		nil
	end

	def print_heat_map
		puts
		self.rows.each do |row|
			row.each do |hex|
				print hex.heat_symbol
			end
			puts
		end
		nil
	end

	def print_rainfall_map
		puts
		self.rows.each do |row|
			row.each do |hex|
				print hex.rain_symbol
			end
			puts
		end
		nil
	end

	private

	def generate_land!
		print '.'
		self.attempts += 1
		self.rows = []
		self.peaks = []
		self.seas = []
		array = @wp.generateTerrain(self.lengthExpo, RANGE, ROUGHNESS)
		y = 0
		hills = 0
		total = 0
		self.size = array.length
		array.each do |r|
			x = 0
			row = []
			r.each do |v|
				hex = MapHex.new({x: x, y: y, elevation: v, temperature: calculate_temperature(y, v), sea: sea?(v), mountain: mountain?(v), hill: hill?(v)})
				if hex.sea?
					self.seas << hex
				elsif hex.mountain?
					self.peaks << hex
				elsif hex.hill?
					hills += 1
				end
				x += 1
				total += 1
				row << hex
			end
			self.rows << row
			y += 1
		end
		# remove 1 hex seas
		self.seas.each do |hex|
			sea_count = hex.neighbours.map do |hex2|
				hex2.y >= 0 && hex2.x >= 0 && self.rows[hex2.y] && self.rows[hex2.y][hex2.x]
			end.sum do |hex2|
				hex2 && hex2.sea? ? 1 : 0
			end
			if sea_count < 1
				hex.terrain = nil
				self.rows[hex.y][hex.x] = hex
			end
		end
		# calculate ratios
		sea_ratio = self.seas.length.to_f / total.to_f
		mountain_ratio = self.peaks.length.to_f / total.to_f
		hill_ratio = hills.to_f / total.to_f
		if sea_ratio < MIN_SEA || sea_ratio > MAX_SEA || mountain_ratio < MIN_MOUNTAIN || mountain_ratio > MAX_MOUNTAIN || hill_ratio < MIN_HILLS || hill_ratio > MAX_HILLS
			return generate_land!
		end
		#print_map
		puts
		puts "Base map generated after #{self.attempts} attempts (Sea: #{(sea_ratio * 100).round}%, Mountains: #{(mountain_ratio * 100).round}%, Hills: #{(hill_ratio * 100).round}%)"
		#@wp.outputArrayASCII(array, RANGE * 2)
	end

	def generate_rivers!
		self.rivers = []
		list = self.peaks
		list.each do |peak|
			peak.neighbours.map do |hex|
				!edge?(hex) && self.rows[hex.y] && self.rows[hex.y][hex.x]
			end.select do |hex|
				hex && !(hex.mountain? || hex.sea?) && hex.elevation < peak.elevation
			end.sort do |a, b|
				a.elevation <=> b.elevation
			end.each do |mouth|
				mapped_neighbours = mouth.neighbours.map do |hex|
					hex.y >= 0 && hex.x >= 0 && self.rows[hex.y] && self.rows[hex.y][hex.x]
				end.select do |hex|
					hex
				end
				unless mapped_neighbours.sum{|hex| hex.mountain? ? 1 : 0} > 1 || 
					mapped_neighbours.any?{|hex| hex.river? || hex.sea? }
					draw_river!(mouth)
				end
			end
		end
		#print_map
	end

	def draw_river!(river, previous=[])
		river.terrain = 'River'
		self.rows[river.y][river.x] = river
		self.rivers << river
		previous << river
		mapped_neighbours = river.neighbours.map do |hex|
			hex.y >= 0 && hex.x >= 0 && self.rows[hex.y] && self.rows[hex.y][hex.x]
		end.select do |hex|
			hex && !previous.include?(hex) && !hex.river?
		end
		# if next to sea or edge, river ends
		if mapped_neighbours.empty? || mapped_neighbours.any?{|hex| hex.sea? || edge?(hex)}
			unless previous.length > self.lengthExpo # remove silly short rivers
				river.terrain = nil
				river.rainfall = 1
				self.rows[river.y][river.x] = river
				previous.each do |hex|
					hex.terrain = nil 
					hex.rainfall = 2
					self.rows[hex.y][hex.x] = hex
				end
			end
			return
		end
		# otherwise, find the next hex to become part of this river
		next_hex = mapped_neighbours.select do |hex|
			hex.elevation <= river.elevation
		end.sort do |a,b|
			a.elevation <=> b.elevation
		end.first
		unless next_hex || mapped_neighbours.empty?
			# broaden search
			next_hex = mapped_neighbours.select do |hex|
				if hex
					total_rivers = hex.range(2).map do |hex2|
						hex2.y >= 0 && hex2.x >= 0 && self.rows[hex2.y] && self.rows[hex2.y][hex2.x]
					end.sum do |hex2|
						hex2 && hex2.river? ? 1 : 0
					end
					total_rivers < 3
				else
					false
				end
			end.sort do |a,b|
				a.elevation <=> b.elevation
			end.first
			if next_hex
				next_hex.elevation = river.elevation 
				self.rows[next_hex.y][next_hex.x] = next_hex
			end
		end
		if next_hex
			draw_river!(next_hex, previous)
		elsif previous.length < self.lengthExpo # remove silly short rivers
			river.terrain = nil
			river.rainfall = 1
			self.rows[river.y][river.x] = river
			previous.each do |hex|
				hex.terrain = nil 
				hex.rainfall = 2
				self.rows[hex.y][hex.x] = hex
			end
		else
			mapped_neighbours = river.neighbours.map do |hex|
				hex.y >= 0 && hex.x >= 0 && self.rows[hex.y] && self.rows[hex.y][hex.x]
			end.select do |hex|
				hex && !(hex.river? || hex.sea? || hex.mountain? || hex.hill?)
			end
			if mapped_neighbours.count > 1
				river.terrain = 'Sea'
				self.rows[river.y][river.x] = river
				mapped_neighbours.each do |hex|
					hex.terrain = 'Sea'
					self.rows[hex.y][hex.x] = hex
				end
			else
				river.terrain = nil
				river.rainfall = 1
				self.rows[river.y][river.x] = river
				previous.each do |hex|
					hex.terrain = nil 
					hex.rainfall = 2
					self.rows[hex.y][hex.x] = hex
				end
			end
		end
	end

	def assign_moisture!
		self.seas.each do |sea|
			sea.range(2).map do |hex|
				hex.y >= 0 && hex.x >= 0 && self.rows[hex.y] && self.rows[hex.y][hex.x]
			end.select do |hex|
				hex
			end.each do |hex|
				hex.rainfall = 1
				self.rows[hex.y][hex.x] = hex
			end
		end
		self.rivers.each do |river|
			river.range(3).map do |hex|
				hex.y >= 0 && hex.x >= 0 && self.rows[hex.y] && self.rows[hex.y][hex.x]
			end.select do |hex|
				hex
			end.each do |hex|
				if river.distance(hex) < 2
					hex.rainfall = 3
				else
					hex.rainfall = 1
				end
				self.rows[hex.y][hex.x] = hex
			end
		end
		(AQUIFERS * self.lengthExpo).times do
			x = rand(self.size)
			y = rand(self.size)
			aquifer = self.rows[y][x]
			aquifer.rainfall = 4
			aquifer.range(3).map do |hex|
				hex.y >= 0 && hex.x >= 0 && self.rows[hex.y] && self.rows[hex.y][hex.x]
			end.select do |hex|
				hex
			end.each do |hex|
				hex.rainfall = (4 - aquifer.distance(hex))
				self.rows[hex.y][hex.x] = hex
			end
		end
	end

	def calculate_temperature(y, v)
		mid = (self.size / 2.0)
		equator_ratio = ((mid - (mid - y).abs.to_f) / mid)
		height_adj = if v <= -3 * (RANGE / 5)
			-0.75
		elsif v <= -2 * (RANGE / 5)
			-0.5
		elsif v <= -1 * (RANGE / 5)
			-0.25
		elsif v <= 1 * (RANGE / 5)
			0.25
		elsif v <= 2 * (RANGE / 5)
			0.5
		elsif v <= 3 * (RANGE / 5)
			0.75
		else
			1.0
		end
		temp = (50 * (equator_ratio - height_adj)) + rand(5)
	end

	def determine_biomes!
		# Volcanos
		self.lengthExpo.times do
			volcano = self.peaks.sample
			volcano = self.rows[volcano.y][volcano.x]
			volcano.terrain = 'Volcano'
			self.rows[volcano.y][volcano.x] = volcano
		end
		# Biomes
		self.rows.each do |row|
			row.each do |hex|
				unless hex.river? || hex.sea? || hex.mountain? || hex.volcano?
					case hex.rainfall 
					when 0
						if hex.hill?
							# keep
						elsif hex.temperature > 37
							hex.terrain = 'Desert'
						elsif hex.temperature < 27
							hex.terrain = 'Barren'
						elsif hex.temperature < 0
							hex.terrain = 'Wasteland'
						else
							hex.terrain = 'Plains'
						end
					when 1
						if hex.temperature > 37
							hex.terrain = 'Forest' # Jungle
						elsif hex.temperature > 24 && !hex.hill?
							hex.terrain = 'Plains'
						elsif hex.temperature < 0 && !hex.hill?
							hex.terrain = 'Scrubland'
						elsif !hex.hill?
							hex.terrain = 'Forest'
						end
					when 2
						if hex.temperature > 37
							hex.terrain = 'Forest' # Jungle
						elsif hex.temperature < 0 && !hex.hill?
							hex.terrain = 'Scrubland'
						elsif !hex.hill?
							hex.terrain = 'Plains'
						end
					when 3
						if hex.temperature > 37
							hex.terrain = 'Forest' # Jungle
						elsif !hex.hill?
							hex.terrain = 'Swamp'
						end
					when 4
						if hex.temperature > 37
							hex.terrain = 'Forest' # Jungle
						elsif !hex.hill?
							hex.terrain = 'Swamp'
						end
					else
						if hex.hill?
							# nothing
						elsif hex.elevation >= 1.5 * (RANGE / 5) || hex.temperature > 28
							hex.terrain = 'Sea'
							hex.neighbours.map do |hex2|
								hex2.y >= 0 && hex2.x >= 0 && self.rows[hex2.y] && self.rows[hex2.y][hex2.x]
							end.select do |hex2|
								hex2
							end.each do |hex2|
								unless hex2.river? || hex2.mountain? || hex2.sea?
									hex2.terrain = 'Swamp'
									self.rows[hex2.y][hex2.x] = hex2
								end
							end
						else
							hex.terrain = 'Forest'
						end
					end
				end
			end
		end
	end

	def edge?(hex)
		hex.x == 0 || hex.y == 0 || hex.x == (self.size - 1) || hex.y == (self.size - 1)
	end

	def sea?(v)
		v <= -1 * (RANGE / 5)
	end

	def mountain?(v)
		v >= 3 * (RANGE / 5)
	end

	def hill?(v)
		!mountain?(v) && v >= 1.5 * (RANGE / 5)
	end

end