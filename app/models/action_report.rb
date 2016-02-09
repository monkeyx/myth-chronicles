class ActionReport < ActiveRecord::Base
	include Temporal
	
	validates :name, length: {in: 1..50}
	validates :summary, presence: true

	belongs_to :position
	belongs_to :caused_by, class_name: 'Position'

	scope :for_position, ->(position) { where({position_id: position.id })}
	scope :caused_by_another, -> { where("caused_by_id <> 0")}
	scope :since, ->(timestamp) { where(["action_reports.created_at > ?", timestamp])}
	scope :for_user, ->(user) { joins(:position).where(["positions.id = ? OR positions.owner_id = ?", user.character.id, user.character.id])}

	def self.add_report!(position, name, summary, caused_by=nil)
		return unless position && name
		position = position.position unless position.is_a?(Position)
		caused_by = caused_by.position unless caused_by.nil? || caused_by.is_a?(Position)
		report = ActionReport.new(position: position, name: name, summary: summary, game_time: position.game.game_time)
		report.caused_by = caused_by if caused_by
		report.save!
		report
	end
	
	def display_name
		name.gsub('Action','').split(/(?=[A-Z])/).join(' ')
	end

	def as_json(options={})
		{
			name: display_name,
			summary: summary,
			game_time: game_time
		}
	end

	def to_s
		"#{position}: #{display_name}: #{summary}"
	end
end
