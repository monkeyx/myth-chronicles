class Position < ActiveRecord::Base
	POSITION_TYPES = ['Character', 'Army', 'Settlement']

	include Spatial
	include Temporal
	include ActionTypes
	
	validates :name, length: {in: 3..50}
	validates :position_type, inclusion: {in: POSITION_TYPES}
	
	belongs_to :owner, class_name: 'Character'

	has_many :settlement_permissions, dependent: :delete_all
	has_many :position_items, dependent: :delete_all
	alias_method :items, :position_items
	has_many :action_reports, dependent: :delete_all

	before_validation :set_founded_date

	scope :owned_by, ->(owner) { where(owner_id: owner.id ) }
	scope :for_user, ->(user) { where(["id = ? OR owner_id = ?", user.character.id, user.character.id])}
	scope :not_killed, -> { where(killed: false )}
	scope :killed, -> { where(killed: true )}
	scope :order_by_name, -> { order("name ASC")}

	def self.create_character!(game, user, name, character_type)
		raise "Invalid game" unless game
		raise "Invalid user" unless user
		raise "Invalid name" if name.blank?
		raise "Invalid character type" unless Character::CHARACTER_TYPE.include?(character_type)
		position = create!(game: game, name: name, position_type: 'Character', x: 0, y: 0)
		position = Character.new(id: position.id, position: position, character_type: character_type, user: user)
		position.save!
		position
	end

	def self.create_army!(game, owner, name="New Army")
		raise "Invalid game" unless game
		raise "Invalid owner" unless owner && owner.is_a?(Character)
		raise "Invalid name" if name.blank?
		position = create!(game: game, owner: owner, name: name, position_type: 'Army', x: owner.location.x, y: owner.location.y)
		position = Army.new(id: position.id, position: position)
		position.save!
		position
	end

	def self.create_settlement!(game, owner, settlement_type, location=owner.location, name="New #{settlement_type}")
		raise "Invalid game" unless game
		raise "Invalid name" if name.blank?
		raise "Invalid settlement type" unless Settlement::SETTLEMENT_TYPES.include?(settlement_type)
		position = create!(game: game, owner_id: (owner ? owner.id : 0), name: name, position_type: 'Settlement', x: location.x, y: location.y)
		position = Settlement.new(id: position.id, position: position, settlement_type: settlement_type)
		position.save!
		position
	end

	POSITION_TYPES.each do |pos_type|
		define_method("#{pos_type.downcase}?") do 
			self.position_type == pos_type
		end

		scope pos_type.downcase.to_sym, -> { where(position_type: pos_type )}
	end

	def subclass
		return Character if self.character
		return Army if self.army 
		return Settlement if self.settlement
		:unknown
	end

	def subtype
		return self.character.subtype if self.character
		return self.army.subtype if self.army 
		return self.settlement.subtype if self.settlement
		:unknown
	end

	def character
		@character ||= Character.where(id: self.id).first
	end

	def army
		@army ||= Army.where(id: self.id).first
	end

	def settlement
		@settlement ||= Settlement.where(id: self.id).first
	end

	def owner_or_self
		self.owner || self
	end

	# Ownership and alliances

	def belongs_to?(character)
		 character && (character.id == self.id || (self.owner && character.id == self.owner.id))
	end

	def alliance
		return nil unless character || self.owner
		return self.character.alliance if character
		self.owner.alliance
	end

	def neutral?
		self.owner.nil?
	end

	def friendly?(other)
		return false if other.nil?
		return true if self.id == other.id # i am other
		return true if other.owner && other.owner.id == self.id # i am owner of other
		return true if self.owner && self.owner.id == other.id # i am owned by other
		return true if self.owner && other.owner && self.owner.id == other.owner.id # we are owned by same owner
		return true if self.alliance && other.alliance && self.alliance.id == other.alliance.id # we are in same alliance
		false
	end

	# Lifecycle

	def set_founded_date
		if new_record?
			self.game_time = self.game
		end
	end

	# Items
	def item_count(item)
		return 0 unless item
		item = Item.named(item.to_s).first unless item.is_a?(Item)
		return 0 unless item
		pi = PositionItem.for_position(self).for_item(item).has_some.first
		pi.nil? ? 0 : pi.quantity
	end

	def add_items!(item, quantity)
		return 0 unless item
		item = Item.named(item.to_s).first unless item.is_a?(Item)
		return 0 unless item
		if character && !item.magical?
			raise "Invalid item for character"
		end
		pi = PositionItem.for_position(self).for_item(item).first
		pi ||= PositionItem.new(item: item, position: self, quantity: 0)
		pi.quantity += quantity
		pi.save!
		if army
			army.calculate!
		end
		pi.quantity
	end

	def sub_items!(item, quantity)
		add_items!(item, (0 - quantity))
	end

	def remove_all_items!
		PositionItem.for_position(self).destroy_all
	end

	def to_s
		"#{name} (#{id})"
	end

	def colour
		return self.character.colour if self.character
		return self.owner.colour if self.owner 
		nil
	end

	def as_json(options={})
		json = {
			id: id,
			colour: colour,
			name: name,
			type: position_type,
			subtype: subtype,
			location: Hex.in_game(game).at_loc(location).first,
			founded: game_time,
			owner: {
				id: owner_id,
				name: (owner ? owner.name : nil)
			}
		}
		if options[:items] || options[:full]
			json[:items] = position_items.where("quantity > 0").order_by_name
		end
		if options[:permissions] || options[:full]
			json[:permissions] = settlement_permissions.has_some
		end
		if options[:actions] || options[:full]
			json[:actions] = valid_actions
		end
		json
	end
end
