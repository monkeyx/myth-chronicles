class BattleReport < ActiveRecord::Base
	include Combat
	include Spatial
	include Temporal
	
	belongs_to :attacker, class_name: 'Position'
	belongs_to :defender, class_name: 'Position'
	validates :battle_type, inclusion: {in: BATTLE_TYPES}
	validates :summary, presence: true
	# attacker_won
	# defender_won
	validates :attacker_units_destroyed, numericality: {only_integer: true, greater_than_or_equal_to: 0}
	validates :defender_units_destroyed, numericality: {only_integer: true, greater_than_or_equal_to: 0}

	validates :attacker_units_table, presence: true
	validates :defender_units_table, presence: true 

	scope :for_position, ->(position) { where(["attacker_id = ? OR defender_id = ?", position.id])}
	scope :for_user, ->(user) { where(["attacker_id IN (?) OR defender_id IN (?)", (positions = Position.for_user(user).map{|pos| pos.id}), positions ])}
	
	def winner
		attacker_won ? "#{attacker} won" : defender_won ? "#{defender} won" : 'Battle was a draw'
	end

	def as_json(options={})
		json = {
			id: id,
			title: "[A] #{attacker} vs [D] #{defender}",
			winner: winner,
			type: battle_type,
			location: Hex.in_game(game).at_loc(location).first,
			game_time: game_time
		}
		if options[:full]
			json[:summary] = summary 
			json[:attacker] = {
				id: attacker.id,
				name: attacker.name,
				won: attacker_won,
				units_lost: attacker_units_destroyed,
				attacker_units_table: attacker_units_table
			}
			json[:defender] = {
				id: defender.id,
				name: defender.name,
				won: defender_won,
				units_lost: defender_units_destroyed,
				defender_units_table: defender_units_table
			}
		end
		json
	end
end
