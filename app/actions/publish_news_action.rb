class PublishNewsAction < BaseAction
	
	PARAMETERS = {
			'text': { required: true, type: 'string'}
		}
	
	POSITION_TYPE = [Character]
	SUBTYPE = :any

	DESCRIPTION = "<p>Publishes news from your alliance which will spread across the lands.</p><p><strong>Action Points Cost</strong>: 2</p>"

	ALLIANCE = true
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
		settlement = Settlement.in_game(self.position.game).at_loc(self.position.location).first
		unless settlement
			add_error('invalid_location')
			return false
		end
		alliance = self.position.alliance
		unless alliance
			add_error('not_in_alliance')
			return false
		end
		unless alliance.can_publish_news?(self.position)
			add_error('no_rights')
			return false
		end
		Rumour.publish_news!(self.position, params['text'])
		add_report({news: params['text']})
		return true
	end

	def action_point_cost 
		NORMAL_ACTION
	end

end