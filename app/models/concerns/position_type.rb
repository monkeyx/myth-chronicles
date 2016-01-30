module PositionType
	extend ActiveSupport::Concern

	included do 
		belongs_to :position # never dependent destroy because we use position classes to track destroyed positions

		has_many :position_items, through: :position

		default_scope { joins(:position)}

		scope :owned_by, ->(owner) { joins(:position).where(["positions.owner_id = ?", owner.id ]) }
		scope :in_alliance, ->(alliance) { joins(:position).where(["positions.owner_id IN (?) OR id IN (?)", alliance.alliance_members.map{|am| am.member_id}, alliance.alliance_members.map{|am| am.member_id}])}
		scope :neutral, -> { joins(:position).where("positions.owner_id = 0") }
		scope :in_game, ->(game) { joins(:position).where(["positions.game_id = ?", game.id]) }
		scope :at, ->(x,y) { joins(:position).where(["positions.x = ? AND positions.y = ?", x, y])}
		scope :at_loc, ->(loc) { at(loc.x, loc.y )}
		scope :order_by_name, -> { joins(:position).order("name ASC")}
		
		before_validation :validate_position
		before_save :save_position
		after_destroy :position_killed

		include Terrain

		def self.around_block(x, y, range)
			loc = Spatial::Location.new(nil, x, y)
			joins(:position).where(["positions.location_id IN (?)", loc.range(range).map{|l| l.id }])
		end

		def self.around(location)
			around_block(location.x, location.y, 1)
		end
	end

	def position_changed?
		self.position.name_changed? || self.position.owner_id_changed? || self.position.x_changed? || self.position.y_changed?
	end

	def events
		self.position.events
	end

	def items
		self.position_items
	end

	def item_count(item)
		self.position.item_count(item)
	end

	def add_items!(item, quantity)
		self.position.add_items!(item, quantity)
	end

	def sub_items!(item, quantity)
		self.position.sub_items!(item, quantity)
	end

	def name
		self.position.name
	end

	def name=(n)
		self.position.name = n 
	end

	def game
		self.position.game 
	end

	def owner
		self.position.owner
	end

	def owner=(o)
		self.position.owner = o
	end

	def user
		is_a?(Character) ? User.where(id: read_attribute(:user_id)).first : (owner ? owner.user : nil)
	end

	def alliance
		is_a?(Character) ? Alliance.where(id: read_attribute(:alliance_id)).first : position.alliance
	end

	def neutral?
		self.position.neutral?
	end

	def friendly?(other)
		position.friendly?(other)
	end

	def x
		self.position.x
	end

	def x=(n)
		self.position.x = n 
	end

	def y
		self.position.y
	end

	def y=(n)
		self.position.y = n
	end

	def location
		self.position.location 
	end

	def location=(l)
		self.position.location = l
	end

	def distance(other)
		self.position.distance(other)
	end

	def move(direction)
		self.position.move(direction)
	end

	def hex
		self.position.hex
	end

	def in_friendly_territory?
		hex.territory && friendly?(hex.territory)
	end

	def at_friendly_settlement?
		settlement = Settlement.in_game(self.game).at_loc(self.location).first
		settlement && friendly?(settlement) && settlement
	end

	def at_own_settlement?
		settlement = Settlement.in_game(self.game).at_loc(self.location).first
		settlement && settlement.owner && (settlement.owner.id  == self.id || settlement.owner.id == self.owner.id) && settlement
	end

	def terrain
		self.position.hex.read_attribute(:terrain)
	end

	def colour
		self.position.colour
	end

	def belongs_to?(character)
		self.position.belongs_to?(character)
	end

	def action_reports
		self.position.action_reports
	end

	def validate_position
		unless self.position.valid?
			self.errors = self.position.errors
		end
	end

	def save_position
		if position_changed?
			unless self.position.save
				self.errors = self.position.errors
			end
		end
	end

	def position_killed
		self.position.update_attributes!(killed: true)
	end

	def to_s
		"#{name} (#{id})"
	end
end