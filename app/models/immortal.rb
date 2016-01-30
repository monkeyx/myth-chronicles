class Immortal < ActiveRecord::Base
	include Temporal

	validates :name, length: {in: 1..50}
	validates :character_type, inclusion: {in: Character::CHARACTER_TYPE}
	belongs_to :game
	belongs_to :user

	scope :in_game, ->(game) { where(game_id: game.id)}

	def to_s
		"#{name} (G#{game.id})"
	end

	def as_json(options={})
		{
			game: game,
			name: name,
			type: character_type
		}
	end
end
