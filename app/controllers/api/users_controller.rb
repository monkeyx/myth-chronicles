class Api::UsersController < Api::BaseController

	def show
		render json: current_user, status: :ok
	end
end