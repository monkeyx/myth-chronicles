class GivePermissionsAction < BaseAction

	PARAMETERS = {
			'army_id': { required: true, type: 'integer'},
			'full': { required: false, type: 'boolean'},
			'owned_item_id': { required: false, type: 'integer'},
			'quantity': { required: false, type: 'integer'}
		}
	
	POSITION_TYPE = [Settlement]
	SUBTYPE = :any

	DESCRIPTION = "<p>Gives permissions to the specified army to pick up items from this settlement. The army needs to be present at the settlement before permissions can be granted.</p><p><strong>Action Points Cost</strong>: 1</p>"

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
		target = Position.where(id: params['army_id']).first
		unless target && target.army?
			add_error('invalid_position')
			return false
		end
		if is_true?('full')
			self.position.give_full_permission!(target)
			add_report({target: target}, 'Full')
			ActionReport.add_report!(target, 'Permissions Graned', I18n.translate('actions.GivePermissionsAction.Position-Full', {settlement: self.position, target: target}), self.position)
		else
			item = Item.where(id: params['owned_item_id']).first
			unless item
				add_error('invalid_item')
				return false 
			end
			quantity = params['quantity'].to_i
			self.position.give_pickup_permission!(target, item, quantity)
			add_report({target: target, item: item, quantity: quantity}, 'Pickup')
			ActionReport.add_report!(target, 'Permissions Graned', I18n.translate('actions.GivePermissionsAction.Position-Item', {settlement: self.position, target: target, item: item, quantity: quantity}), self.position)
		end
		return true
	end

	def action_point_cost 
		FAST_ACTION
	end

end