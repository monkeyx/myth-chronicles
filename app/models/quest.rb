class Quest < ActiveRecord::Base
	require 'yaml'

	belongs_to :character

	validates :status, presence: true
	validates :description, presence: true

	scope :for_character, ->(character) { where(character_id: character.id)}
	scope :completed, -> { where(completed: true)}
	scope :in_progress, -> { where(completed: false)}

	before_save :persist_data
	after_find :quest_instance

	def self.give_quest!(character, quest_class, quest_template)
		initial_data = YAML.load_file("#{Rails.root}/config/quests/#{quest_template}.yml")
		q = Quest.create!(character: character, class_name: quest_class.name, status: '<!-- Initial Status -->', description: '<!-- Initial Description -->', 
			completed: false, data: initial_data.to_json)
		q.check_and_complete!
	end

	def quest_class
		Object.const_get(self.class_name)
	end

	def quest_instance
		@quest_instance ||= quest_class.new(self.character, self.data.blank? ? {} : JSON.parse(self.data))
	end

	def persist_data
		self.data = quest_instance.data.to_json
	end

	def check_and_complete!
		transaction do 
			q = quest_instance
			q.check!
			if q.completed && !self.completed
				give_reward!
				next_quest!
				add_report!(q.status, q.description)
			end
			update_attributes(completed: q.completed, status: q.status, description: q.description)
		end
	end

	def add_report!(status, description)
		ActionReport.add_report!(self.character, status, description, self.character)
	end

	def give_reward!
		quest_instance.rewards.each do |reward|
			if reward.item
				quest_instance.position.add_items!(reward.item, reward.item_quantity)
			end
			if reward.gold
				self.character.add_gold!(reward.gold)
			end
			if reward.xp
				self.character.add_experience_points!(reward.xp)
			end
		end
	end

	def next_quest!
		if quest_instance.next_quest_class
			Quest.give_quest!(self.character, quest_instance.next_quest_class, quest_instance.next_quest_template)
		end
	end

	def as_json(options={})
		{
			status: self.status,
			description: self.description
		}
	end
end