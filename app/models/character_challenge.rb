class CharacterChallenge < ActiveRecord::Base
	CHALLENGE_EXPIRATION = 10

	include Temporal
	include Spatial

	belongs_to :character
	belongs_to :challenger, class_name: 'Character'
	belongs_to :game

	scope :for_character, ->(character) { where(["character_id = ? OR challenger_id = ?", character.id, character.id])}

	def expired?
		(self.game_time + CHALLENGE_EXPIRATION) < self.game.game_time
	end

	def reject!
		character.use_renown!(1)
		# TODO Add Notification
		self.destroy
	end

	def cancel!
		self.destroy
	end

	def accept!
		challenger.fight!(character)
		challenger.add_renown!(1) unless challenger.destroyed?
		character.add_renown!(1) unless character.destroyed?
		true
	end

	def as_json(options={})
		{
			id: id,
			from: {
				id: challenger.id,
				name: challenger.name
			},
			to: {
				id: character.id,
				name: character.name
			},
			issued: game_time,
			location: location
		}
	end
end