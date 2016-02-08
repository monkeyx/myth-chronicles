class ApplicationController < ActionController::Base
	layout :layout_by_resource
  	helper_method :forem_user

  	include DeviseTokenAuth::Concerns::SetUserByToken
  	include ActionController::MimeResponds
  	
	respond_to :html, :json
	before_action :configure_permitted_parameters, if: :devise_controller?

	before_filter :add_allow_credentials_headers
	skip_before_filter :verify_authenticity_token
	before_filter :cors_preflight_check
	after_filter :cors_set_access_control_headers


	def cors_set_access_control_headers
		headers['Access-Control-Allow-Origin'] = '*'
		headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
		headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
		headers['Access-Control-Max-Age'] = '1728000'
	end

	def cors_preflight_check
		if request.method == 'OPTIONS'
		  headers['Access-Control-Allow-Origin'] = '*'
		  headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
		  headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token'
		  headers['Access-Control-Max-Age'] = '1728000'

		  render :text => '', :content_type => 'text/plain'
		end
	end

	def add_allow_credentials_headers
		# https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS#section_5
		#
		# Because we want our front-end to send cookies to allow the API to be authenticated
		# (using 'withCredentials' in the XMLHttpRequest), we need to add some headers so
		# the browser will not reject the response
		response.headers['Access-Control-Allow-Origin'] = request.headers['Origin'] || '*'
		response.headers['Access-Control-Allow-Credentials'] = 'true'
	end

	rescue_from CanCan::AccessDenied do |exception|
	    redirect_to main_app.root_path, :alert => exception.message
	end

	protected

	def not_found
	  raise ActionController::RoutingError.new('Not Found')
	end

	def layout_by_resource
	    if devise_controller?
	      "devise"
	    else
	      "application"
	    end
	end

	def configure_permitted_parameters
		devise_parameter_sanitizer.for(:sign_up) << :name
	    devise_parameter_sanitizer.for(:sign_up) << :character_type
	end

	def forem_user
		current_user
	end
	  
end
