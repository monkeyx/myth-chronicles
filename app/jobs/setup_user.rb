class SetupUser
	include Resque::Plugins::Status

	@queue = :setup

	attr_accessor :user

	def self.schedule(user)
		create(id: user.id)
	end

	def perform
		self.user = User.where(id: options['id']).first
		if self.user
			begin
				SetupUser.setup!(user)
			rescue => e
				set_status(:error, e.to_s)
				Rails.logger.info "Setup User: #{options['id']}: ERROR: #{e}"
				Rails.logger.error e.backtrace
			end
		end
	end

	def self.setup!(user)
		return if user.setup_complete?
		Rails.logger.info "Setup User: #{user}: START"
		user.transaction do
			character = user.character
			settlement = Settlement.neutral.of_type(Character::CHARACTER_SETTLEMENT_TYPE[user.character_type]).first
	        raise "No neutral settlement found for #{user.character_type}" if settlement.nil?
	        character.location = settlement.location 
	        character.save!
	        character.create_unit!

	        settlement.owner = character
	        unless settlement.city?
	        	settlement.name = "#{character.name}'s #{settlement.settlement_type}"
	        end
	        settlement.save!

	        game = user.game
	        game.touch # update neutral counts
	        game.save!

	        unless character.hero?
	        	army = character.army
	        	army.update_attributes(guarding: true)
		    	raise "Invalid terrain for #{settlement.settlement_type} (#{settlement.terrain}) at #{settlement.hex}" if settlement.recruitment_race_item.nil?
	            race = settlement.recruitment_race_item
		        (1..game.year).each do
		          Unit.create_unit!(army, race)
		        end
		    end

	        character.gold = 100 + (game.year * 100)
	        character.save!

	        if game.year >= 10
	        	if character.slot_available?(:armour)
	        		rank = (game.year / 10).round
	        		item = Item.create_magic_item!(:armour, Character::CHARACTER_ATTRIBUTES.sample, rank)
	        		character.update_attributes!(armour: item)
	        	end
	        	if game.year >= 20
	        		if character.slot_available?(:weapon)
		        		rank = (game.year / 20).round
		        		item = Item.create_magic_item!(:weapon, Character::CHARACTER_ATTRIBUTES.sample, rank)
		        		character.update_attributes!(weapon: item)
		        	end
		        	if game.year >= 30
		        		if character.slot_available?(:ring)
			        		rank = (game.year / 30).round
			        		item = Item.create_magic_item!(:ring, Character::CHARACTER_ATTRIBUTES.sample, rank)
			        		character.update_attributes!(ring: item)
			        	end
			        	if game.year >= 40
			        		if character.slot_available?(:amulet)
				        		rank = (game.year / 40).round
				        		item = Item.create_magic_item!(:amulet, Character::CHARACTER_ATTRIBUTES.sample, rank)
				        		character.update_attributes!(amulet: item)
				        	end
			        	end
		        	end
	        	end
	        end

	        #character.give_first_quest!
	        user.update_attributes!(setup_complete: true)
	    	user.send_completion!
	    	game.post_on_forum!("Greetings from #{character.name}", "A new #{character.character_type} has risen in #{game.name}.\n\n#{character.name} joined on #{game.game_time}.", user)
	    end
	    Rails.logger.info "Setup User: #{user}: FINISH"
	end
end