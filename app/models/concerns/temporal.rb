module Temporal
	extend ActiveSupport::Concern

	class GameTime
		include Seasons

		attr_accessor :cycle, :season, :year, :age

		def initialize(cycle, season, year, age)
			self.cycle = cycle
			self.season = season 
			self.year = year
			self.age = age
		end

		def copy
			GameTime.new(self.cycle, self.season, self.year, self.age)
		end

		def diff(other)
			raise "Different age" if self.age != other.age
			d = (self.year - other.year) * 16
			d += ((self.season - other.season) * 4)
			d += (self.cycle - other.cycle)
			d
		end

		def ==(other)
			return false if other.nil?
			self.cycle == other.cycle && self.season == other.season && self.year == other.year && self.age == other.age
		end

		def >(other)
			return false if other.nil?
			return self.age > other.age unless self.age == other.age
			return self.year > other.year unless self.year == other.year
			return self.season > other.season unless self.season == other.season
			self.cycle > other.cycle
		end

		def <(other)
			return false if other.nil?
			other > self
		end

		def +(cycles)
			copy.add_cycles(cycles)
		end

		def -(cycles)
			copy.sub_cycles(cycles)
		end

		def total_cycles
			(self.cycle - 1) + ((self.season - 1)* 4) + ((self.year - 1) * 16)
		end

		def add_cycles(cycles)
			n = total_cycles + cycles
			self.year = 1 + (n / 16.0).to_i
			n -= ((self.year - 1) * 16)
			self.season = 1 + (n / 4.0).to_i
			n -= ((self.season - 1) * 4)
			self.cycle = 1 + n
			self
		end

		def sub_cycles(cycles)
			add_cycles((0 - cycles))
		end

		def add_seasons(seasons)
			add_cycles((seasons * 4))
		end

		def sub_seasons(seasons)
			sub_cycles((seasons * 4))
		end

		def add_years(years)
			add_cycles((years * 16))
		end

		def sub_years(years)
			sub_cycles((years * 16))
		end

		def season_name
			SEASONS[(self.season - 1)]
		end

		def to_short_s
			"#{self.cycle.ordinalize} #{season_name}, A#{self.age}.#{self.year}Y"
		end

		def to_s
			"#{self.cycle.ordinalize} Cycle of #{season_name}, #{self.year.ordinalize} Year of the #{self.age.ordinalize} Age"
		end

		def as_json(options={})
			{
				cycle: cycle,
				season: season,
				year: year,
				age: age,
				display: to_short_s,
				long_display: to_s
			}
		end
	end

	included do 
		validates :cycle, numericality: {only_integer: true, greater_than_or_equal_to: 0}
		validates :season, numericality: {only_integer: true, greater_than_or_equal_to: 0}
		validates :year, numericality: {only_integer: true, greater_than_or_equal_to: 0}
		validates :age, numericality: {only_integer: true, greater_than_or_equal_to: 0}

		scope :when, ->(cycle, season, year, age) { where(cycle: cycle, season: season, year: year, age: age )}
		scope :when_time, ->(game_time) { where(cycle: game_time.cycle, season: game_time.season, year: game_time.year, age: game_time.age )}
		
		include Seasons
	end

	def game_time
		GameTime.new(self.cycle, self.season, self.year, self.age)
	end

	def game_time=(gt)
		self.cycle = gt.cycle
		self.season = gt.season
		self.year = gt.year
		self.age = gt.age
	end

	def season_name
		SEASONS[(self.season - 1)]
	end

end