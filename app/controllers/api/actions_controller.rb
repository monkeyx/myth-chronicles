class Api::ActionsController < Api::BaseController

	before_filter :set_position, except: [:status, :cancel]
	before_filter :check_authorisation, except: [:status, :cancel]

	EXCLUDE_PARAMS = ['action','action_type','controller','format','type','id']

	def create
		begin
			action_class = Object.const_get "#{params[:action_type]}Action"
			unless action_class < BaseAction
				return head :method_not_allowed
			end
		rescue => e 
			return head :method_not_allowed
		end

		sparams = {}
		params.keys.each {|key| k = key.to_s.strip; sparams[k] = params[key] unless EXCLUDE_PARAMS.include?(k)}

		action = action_class.new(current_user, @current_position, sparams)

		unless action.validate
			render json: {errors: action.errors, params: action.params}, status: :unprocessable_entity
		else
			if Rails.env.test?
				success, errors = action.run!
				if success
					head :ok
				else
					render json: {errors: action.errors}, status: :unprocessable_entity
				end
			else
				queue_id = action.enqueue
				render json: {id: queue_id }, status: :ok
			end
		end
		
	end

	def status
		render json: {status: BaseAction.status(params[:id])}
	end

	def cancel
		if BaseAction.cancel(params[:id])
			head :ok
		else
			head :not_found
		end
	end
end
