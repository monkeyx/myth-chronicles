class CaptureSettlementAction < BaseAction

	PARAMETERS = {
			
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Attempt to capture the settlement at this location. This will only work if your character can own settlements of this type and there are no guarding armies protecting the settlement. Will not work on friendly or neutral settlements.</p><p><strong>Action Points Cost</strong>: 4</p>"

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
		unless settlement.allowed_owner_type?(self.position.owner.character_type)
			add_error('invalid_settlement')
			return false
		end
		if self.position.friendly?(settlement)
			add_error('target_friendly')
			return false
		end
		if Army.at_loc(self.position.location).guarding.any?{|army| army.friendly?(settlement)}
			add_error('target_defended')
			return false
		end
		previous_owner = settlement.owner
		settlement.owner = self.position.owner
		settlement.save!
		add_report({settlement: settlement, previous_owner: previous_owner}, 'Success')
		ActionReport.add_report!(previous_owner, 'Settlement Lost', I18n.translate('actions.CaptureSettlementAction.Owner', {army: self.position, settlement: settlement}), self.position)
		return true
	end

	def action_point_cost 
		SLOW_ACTION
	end

end