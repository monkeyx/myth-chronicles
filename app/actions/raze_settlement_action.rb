class RazeSettlementAction < BaseAction
	
	PARAMETERS = {
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Razes an unguarded enemy settlement, reducing its defences and eventually turning it into a ruin. You will loot any items in its inventory if it is completely destroyed.</p><p><strong>Action Points Cost</strong>: 4</p>"

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
		self.position.units.each do |unit|
			if unit.check_attribute(:strength_rating, (settlement.defence_rating * 4))
				settlement.defence_rating -= 1
				if settlement.defence_rating < 0
					settlement.raze!(self.position)
					add_report({settlement: settlement}, 'Success')
					Rumour.report_settlement_razed!(settlement)
					ActionReport.add_report!(settlement.owner, 'Settlement Razed', I18n.translate('actions.RazeSettlementAction.Razed', {army: self.position, settlement: settlement}), self.position)
					return true
				end
			end
		end
		if settlement.defence_rating_changed?
			ActionReport.add_report!(settlement.owner, 'Fortification Damaged', I18n.translate('actions.RazeSettlementAction.Damaged', {army: self.position, settlement: settlement, defence_rating: settlement.defence_rating}), self.position)
		end
		settlement.save!
		add_report({settlement: settlement, defence_rating: settlement.defence_rating}, 'Failure')
		Rumour.report_settlement_razed!(settlement)
		return true
	end

	def action_point_cost 
		SLOW_ACTION
	end

end