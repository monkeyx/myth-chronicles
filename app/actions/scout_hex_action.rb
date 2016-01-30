class ScoutHexAction < BaseAction
	
	PARAMETERS = {
			'hex': { required: true, type: 'string'}
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Scouts a neighbouring hex to find out details of any armies located there.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		hex = Hex.at_id(params['hex']).first
		unless hex && (hex.location == self.position.location || hex.location.adjacent?(self.position.location))
			add_error('invalid_location')
			return false
		end
		army_count = self.position.scout!(hex)
		if army_count > 0
			add_report({hex: hex, army_count: "#{army_count} #{'army'.pluralize(army_count)}"}, 'Success')
		else
			add_report({hex: hex}, 'Failure')
		end
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end