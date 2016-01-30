class CharacterRumour < ActiveRecord::Base
	include Temporal
	include Spatial

	belongs_to :character
	belongs_to :rumour
	belongs_to :game

	scope :for_character, ->(character) { where({character_id: character.id})}
	scope :for_rumour, ->(rumour) { where({rumour_id: rumour.id})}
end