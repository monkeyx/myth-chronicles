class Api::ReportsController < Api::BaseController
	include CleanPagination

	before_filter :set_position, only: [:show, :events, :market, :notifications]
	before_filter :check_authorisation, only: [:show, :events, :market, :notifications]

	def show
		render json: @current_position, status: :ok
	end

	def map
		unless current_user.character && current_user.setup_complete
			return head :not_found
		end
		unless params[:x].is_i? && params[:y].is_i?
			return render json: {error: 'Invalid parameters'}, status: :unprocessable_entity
		end
		x = params[:x].to_i
		y = params[:y].to_i
		hexes = Hex.in_game(current_user.game).around_block(x,y,5)
		rows = {}
		hexes.each do |hex|
			rows[hex.y] ||= {}
			rows[hex.y][hex.x] = hex
		end
		render json: rows, status: :ok
	end

	def events
		unless current_user.character && current_user.setup_complete
			return head :not_found
		end
		max_per_page = params[:max_per_page] || 10
		paginate ActionReport.for_position(@current_position).count, max_per_page.to_i do |limit, offset|
			render json: ActionReport.for_position(@current_position).order('updated_at DESC').limit(limit).offset(offset), status: :ok
		end
	end

	def market
		unless current_user.character && current_user.setup_complete
			return head :not_found
		end
		max_per_page = params[:max_per_page] || 10
		paginate Market.for_position(@current_position).count, max_per_page.to_i do |limit, offset|
			render json: Market.for_position(@current_position).joins(:item).order('items.name ASC').limit(limit).offset(offset), status: :ok
		end
	end

	def notifications
		unless current_user.character && current_user.setup_complete
			return head :not_found
		end
		since = params[:since].blank? ? (Time.now - 1.hour).to_s : Time.at((params[:since].to_i / 1000.0))
		render json: ActionReport.for_position(@current_position).caused_by_another.since(since).order('updated_at DESC'), status: :ok
	end

	def quests
		unless current_user.character && current_user.setup_complete
			return head :not_found
		end
		max_per_page = params[:max_per_page] || 10
		paginate Quest.for_character(current_user.character).in_progress.count, max_per_page.to_i do |limit, offset|
			render json: Quest.for_character(current_user.character).in_progress.order('name ASC').limit(limit).offset(offset), status: :ok
		end
	end

	def battle_report
		unless current_user.character && current_user.setup_complete
			return head :not_found
		end
		unless params[:id].blank?
			br = BattleReport.for_user(current_user).where(id: params[:id]).first
			unless br 
				raise ActiveRecord::RecordNotFound
			else
				render json: br.as_json({full: true}), status: :ok
			end
		else
			max_per_page = params[:max_per_page] || 10
			paginate BattleReport.for_user(current_user).count, max_per_page.to_i do |limit, offset|
				render json: BattleReport.for_user(current_user).order('updated_at DESC').limit(limit).offset(offset), status: :ok
			end
		end
	end

	def alliances
		max_per_page = params[:max_per_page] || 10
		paginate Alliance.in_game(current_user.game).count, max_per_page.to_i do |limit, offset|
			render json: Alliance.in_game(current_user.game).order('name ASC').limit(limit).offset(offset), status: :ok
		end
	end

	def immortals
		max_per_page = params[:max_per_page] || 10
		paginate Immortal.in_game(current_user.game).count, max_per_page.to_i do |limit, offset|
			render json: Immortal.in_game(current_user.game).order('name ASC').limit(limit).offset(offset), status: :ok
		end
	end
	
	def index
		unless current_user.character && current_user.setup_complete
			return head :not_found
		end
		max_per_page = params[:max_per_page] || 10
		finder = Position.for_user(current_user).not_killed
		if params[:armies]
			finder = finder.army
		end
		if params[:settlements]
			finder = finder.settlement
		end
		paginate finder.count, max_per_page.to_i do |limit, offset|
			render json: finder.order('name ASC').limit(limit).offset(offset), status: :ok
		end
	end
end
