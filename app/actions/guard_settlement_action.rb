class GuardSettlementAction < BaseAction
	
	PARAMETERS = {
			
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Guards the settlement at this location from attack. Can only guard friendly settlements. Will keep guarding until the army moves.</p><p><strong>Action Points Cost</strong>: 2</p>"

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
		unless self.position.friendly?(settlement)
			add_error('not_friendly')
			return false
		end
		self.position.guarding = true
		self.position.save!
		add_report({settlement: settlement}, 'Success')
		ActionReport.add_report!(settlement, 'Guarded', I18n.translate('actions.GuardSettlementAction.Settlement', {army: self.position, settlement: settlement}), self.position)
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end