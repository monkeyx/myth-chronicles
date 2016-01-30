class Api::CharactersController < Api::BaseController

	def show
		unless current_user.character && current_user.setup_complete
			return head :not_found
		end
		render json: current_user.character, status: :ok
	end

	def create
		game = Game.where(id: params[:game_id]).first
		character_type = params[:character_type]
		name = params[:name]

		unless game && (character = Position.create_character!(game, current_user, name, character_type))
			return render json: {error: 'Invalid parameters'}, status: :unprocessable_entity
		else
			render json: character, status: :ok
		end
	end
end