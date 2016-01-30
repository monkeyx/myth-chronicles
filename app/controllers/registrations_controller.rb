class RegistrationsController < Devise::RegistrationsController

	def require_no_authentication
	end
	
	protected

	def after_sign_up_path_for(resource)
		'/#sign_in'
	end
end