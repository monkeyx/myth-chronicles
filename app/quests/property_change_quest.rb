#
# property
# => name - name of property on position to check
# => original - original value of the property
# => target - target value of the property. if not set will determine using property_change
# => change - change expected to original value
# => any - accept any change?
#
class PropertyChangeQuest < BaseQuest

	def property_sym
		self.data['property']['name'].to_sym
	end

	def property_original
		self.data['property']['original']
	end

	def property_value
		position.send(property_sym)
	end

	def property_target
		self.data['property']['target']
	end

	def property_change
		self.data['property']['change']
	end

	def accept_any_change?
		self.data['property']['any']
	end

	def property_changed?
		property_value != property_original
	end

	def check!
		return (self.failed = true) unless find_position
		return (self.completed = false) unless property_changed?
		p = find_position
		if p
			self.data['property']['original'] ||= property_value
			unless accept_any_change? || self.data['property']['target']
				self.data['property']['target'] = (property_value + property_change)
			end
		end
		unless accept_any_change? || property_value == property_target
			return (self.completed = false) 
		else
			return (self.completed = true)
		end
	end
end