class TrainUnitAction < BaseAction
	
	PARAMETERS = {
			'unit_id': { required: true, type: 'integer'},
			'training': { required: true, type: 'string'}
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Trains the unit at the local guild, provided one is present. Costs 100 gold (200 for stupid races and 50 for smart).</p><p><strong>Action Points Cost</strong>: 2</p>"

	ALLIANCE = false
	NO_ALLIANCE = false
	SETTLEMENT_REQUIRED = true

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
		unit = Unit.where(id: params['unit_id']).first
		unless unit && unit.army.id == self.position.id
			add_error('invalid_unit')
			return false
		end
		unless unit.humanoid?
			add_error('invalid_unit')
			return false
		end
		settlement = Settlement.at_loc(self.position.location).guild.first
		unless settlement
			add_error('invalid_location')
			return false
		end
		training = params['training']
		unless !training.blank? && Training::ALL_TRAINING.include?(training)
			add_error('invalid_training')
			return false
		end
		if self.position.owner.gold < unit.training_cost
			add_error('insufficient_gold')
			return false
		end
		self.position.owner.use_gold!(unit.training_cost)
		unit.training = training
		unit.save!
		if settlement.owner
			settlement.owner.add_gold!((unit.training_cost * 0.1).round)
			# TODO Add notification
		end
		add_report({unit: unit, cost: unit.training_cost, training: training})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end