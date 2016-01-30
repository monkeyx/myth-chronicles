module Seasons
	extend ActiveSupport::Concern

	SEASONS = ['Newbirth', 'Firelight', 'Harvest', 'Coldhearth']

	SEASONAL_MANA_POINTS_GENERATION = [4, 8, 4, 4]
	SEASONAL_ACTION_POINTS_GENERATION = [16, 8, 8, 8]
	SEASONAL_RESOURCE_PRODUCTION = [1, 1, 2, 1]
	SEASONAL_DIFFICULT_TERRAIN = [false, false, false, true]

	def season_difficult_terrain?
		SEASONAL_DIFFICULT_TERRAIN[self.season]
	end

	def season_mana_points
		SEASONAL_MANA_POINTS_GENERATION[self.season]
	end

	def season_action_points
		SEASONAL_ACTION_POINTS_GENERATION[self.season]
	end

	def season_resource_production
		SEASONAL_RESOURCE_PRODUCTION[self.season]
	end
end