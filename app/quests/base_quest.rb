#
# position
# => class - class of position
# => id - id of position, if not set will determine using position_finder
# => finder - finder class method to find suitable position for quest
# status
# => completed - status text when quest is completed
# => failed - status text when is quest has failed
# => incomplete - status text when quest is incomplete
# description
# => completed - description text when quest is completed
# => failed - description text when quest has failed
# => incomplete - description text when quest is incomplete
# reward in rewards
# => item:
		# => name
		# => quantity
# => gold
# => xp
# next_quest
# => class
# => template
class BaseQuest
	attr_accessor :character, :data, :completed, :failed

	def initialize(character, json_data)
		self.data = json_data
		self.completed = false
		self.failed = false
		self.character = character
	end

	def position_class
		Object.const_get(self.data['position']['class'])
	end

	def position_id
		self.data['position']['id']
	end

	def position
		@position ||= position_class.find(position_id)
	end

	def find_position
		p = position if position_id
		p ||= position_class.owned_by(self.character).send(self.data['position']['finder']).first
		self.data['position']['id'] ||= p ? p.id : nil
		p
	end

	def status
		if self.completed
			return format_text self.data['status']['completed']
		elsif self.failed
			return format_text self.data['status']['failed']
		else
			return format_text self.data['status']['incomplete']
		end
	end

	def description
		if self.completed
			return format_text self.data['description']['completed']
		elsif self.failed
			return format_text self.data['description']['failed']
		else
			return format_text self.data['description']['incomplete']
		end
	end

	def rewards
		return [] unless self.data['rewards']
		@rewards = []
		self.data['rewards'].each do |reward|
			@rewards << QuestReward.new(reward)
		end
		@rewards
	end

	def next_quest_class
		return nil unless self.data['next_quest']
		Object.cost_get("Quests").const_get(self.data['next_quest']['class'])
	end

	def next_quest_template
		return nil unless self.data['next_quest']
		self.data['next_quest']['template']
	end

	def format_text(text)
		self.data.keys.each do |k|
			if self.data[k].respond_to?(:keys)
				self.data[k].keys.each do |k2|
					if self.data[k][k2].respond_to?(:to_s)
						text = text.gsub("%{#{k.to_s}.#{k2.to_s}}", self.data[k][k2].to_s)
					end
				end
			elsif self.data[k].respond_to?(:to_s)
				text = text.gsub("%{#{k.to_s}}", self.data[k].to_s)
			end
		end
		text
	end

	def check!
		raise "No check implementation"
	end
end

class QuestReward
	attr_accessor :item_name, :item_quantity, :xp, :gold

	def initialize(opts={})
		if opts['item']
			self.item_name = opts['item']['name'] if opts['item']['name']
			self.item_quantity = opts['item']['quantity'].to_i if opts['item']['quantity']
			self.item_quantity ||= 1 if self.item_name
		end
		self.xp = opts['xp'].to_i if opts['xp']
		self.gold = opts['gold'].to_i if opts['gold']
	end

	def item
		Item.named(self.item_name).first
	end
end