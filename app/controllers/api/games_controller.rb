class Api::GamesController < Api::BaseController

	def index
		render json: Game.open, status: :ok
	end

	def show
		unless current_user.character && current_user.setup_complete
			return head :not_found
		end
		render json: current_user.game, status: :ok
	end
end