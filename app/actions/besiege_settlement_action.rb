class BesiegeSettlementAction < BaseAction

	PARAMETERS = {
			
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Puts the settlement at this location under siege. This prevents it from trading and if it is a city, will slowly reduce the population's loyalty. In effect until this army moves or is destroyed.</p><p><strong>Action Points Cost</strong>: 4</p>"

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
		settlement = Settlement.at_loc(self.position.location).not_guilds.first
		unless settlement
			add_error('invalid_location')
			return false
		end
		if settlement.neutral?
			add_error('target_neutral')
			return false
		end
		if self.position.friendly?(settlement)
			add_error('target_friendly')
			return false
		end
		self.position.besiege!(settlement)
		add_report({settlement: settlement}, 'Success')
		ActionReport.add_report!(settlement, 'Under Siege', I18n.translate('actions.BesiegeSettlementAction.Settlement', {army: self.position, settlement: settlement}), self.position)
		return true
	end

	def action_point_cost 
		SLOW_ACTION
	end

end