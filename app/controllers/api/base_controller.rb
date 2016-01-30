class Api::BaseController < ApplicationController
	rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
	rescue_from Exception, :with => :api_error

	before_action :authenticate_user!
	
	def set_position
		position_type = params[:type]
		position_id = params[:id]
		case position_type
		when 'Character'
			@current_position = Character.where(id: position_id).first
		when 'Army'
			@current_position = Army.where(id: position_id).first
		when 'Settlement'
			@current_position = Settlement.where(id: position_id).first
		end
		true
	end

	def check_authorisation
		unless current_user && @current_position && @current_position.belongs_to?(current_user.character)
			head :forbidden
			return false
		end
		true
	end

	private
	def record_not_found(error)
		Rails.logger.warning(error)
		render :json => {:error => error.message}, :status => :not_found
	end

	def api_error(error)
		Rails.logger.error(error)
		ExceptionNotifier.notify_exception(error, :env => request.env, :data => {:message => "was doing something wrong"})
		render :json => {:error => error.message}, :status => :unprocessable_entity
	end
end
