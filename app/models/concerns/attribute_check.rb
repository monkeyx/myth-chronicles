module AttributeCheck
	extend ActiveSupport::Concern

	def check_attribute(attribute, target)
		n = self.send(attribute) + rand(6) + 1
		n >= target
	end
end