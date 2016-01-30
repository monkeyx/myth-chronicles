class AttackArmyAction < BaseAction

	PARAMETERS = {
			'army_id': { required: true, type: 'integer'}
		}
	
	POSITION_TYPE = [Army]
	SUBTYPE = :any

	DESCRIPTION = "<p>Attacks the specified army at the current location.</p><p><strong>Action Points Cost</strong>: 4</p>"

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
		defender = Army.where(id: params['army_id']).first
		unless defender && defender.location == self.position.location
			add_error('invalid_location')
			return false
		end
		if self.position.friendly?(defender)
			add_error('target_friendly')
			return false
		end
		br = self.position.fight!(defender)
		unless br
			set_errors self.position.errors
			return false
		end
		add_report({defender: defender, battle_id: br.id}, 'Success')
		ActionReport.add_report!(defender, 'Attacked', I18n.translate('actions.AttackArmyAction.Defender', {army: self.position, defender: defender, battle_id: br.id}), self.position)
		Rumour.report_combat!(self.position, defender)
		return true
	end

	def action_point_cost 
		SLOW_ACTION
	end

end