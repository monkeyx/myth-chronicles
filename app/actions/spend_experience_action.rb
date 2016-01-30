class SpendExperienceAction < BaseAction
	
	PARAMETERS = {
			'attribute': { required: true, type: 'string'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Uses experience points to improve the attribute specified. Costs the current rank squared in experience points to improve by 1 rank.</p><p><strong>Action Points Cost</strong>: 2</p>"

	ALLIANCE = false
	NO_ALLIANCE = false
	SETTLEMENT_REQUIRED = false

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
		attribute = params['attribute'].to_sym
		unless Character::CHARACTER_ATTRIBUTES.include?(attribute)
			add_error('invalid_attribute')
			return false
		end
		cost = self.position.get_attribute(attribute) * self.position.get_attribute(attribute)
		if self.position.experience_points < cost
			add_error('insufficient_experience')
			return false
		end
		self.position.update_attribute(attribute, self.position.get_attribute(attribute) + 1)
		self.position.save!
		self.position.use_experience_points!(cost)
		add_report({attribute: attribute, cost: cost, value: self.position.get_attribute(attribute)})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end