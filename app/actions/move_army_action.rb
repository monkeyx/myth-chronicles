class MoveArmyAction < BaseAction
	
	PARAMETERS = {
			'direction': { required: true, type: 'string'}
		}

	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Moves the army in the specified compass direction as long as it is capable of <a href='/docs/armies'>movement</a>.</p><p><strong>Action Points Cost</strong>: Varies</p>"

	ALLIANCE = false
	NO_ALLIANCE = false
	SETTLEMENT_REQUIRED = false

	attr_accessor :action_point_cost

	def valid_positions
		POSITION_TYPE
	end

	def valid_subtype
		SUBTYPE
	end 

	def parameters
		PARAMETERS
	end

	def transaction!
		direction = params['direction']
		if direction.blank? || !Spatial::DIRECTION_NAMES.include?(direction)
			add_error('invalid_direction')
			return false
		end
		old_location = self.position.location
		new_location = self.position.move(direction)
		if old_location == new_location
			add_error('invalid_direction')
			return false
		end
		hex = Hex.in_game(self.position.game).at_loc(new_location).first
		unless hex 
			add_error('invalid_direction')
			return false
		end

		if hex.impassable? && !hex.water? && !self.position.movement_air?
			add_error('movement_impassable')
			return false
		end

		if hex.impassable? && hex.water? && !(self.position.movement_sea? || self.position.movement_air?)
			add_error('movement_sea')
			return false
		end

		if !hex.water? && !(self.position.movement_land? || self.position.movement_air?)
			add_error('movement_impossible')
			return false
		end

		self.action_point_cost = Army::MOVEMENT_ACTION_POINT_COST
		if hex.difficult? && (!self.position.movement_air? || (hex.water? && self.position.movement_sea?))
			self.action_point_cost *= 2
		end

		self.position.move!(new_location)
		
		add_report({terrain: hex.terrain})

		return true
	end

end