class User < ActiveRecord::Base
  	# Include default devise modules.
  	devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable, :validatable
    include DeviseTokenAuth::Concerns::User

    acts_as_messageable
   
    validates :name, length: {in: 1..50}
    validates :character_type, inclusion: {in: Character::CHARACTER_TYPE }, unless: "self.character_type.blank?"
    # setup_complete
    has_one :character, dependent: :destroy
    
    scope :with_email, ->(email) { where(email: email)}
	scope :in_game, ->(game) { joins({:character => :position}).where(["positions.game_id = ?", game.id]) }
	scope :with_auth_token, ->(token) { where(auth_token: token )}

	after_save :setup_if_ready
	after_create :add_to_mailchimp

	before_validation :set_colour_if_none

	def self.random_colour
		s = ''
		(1..6).each do
			s = s + rand(16).to_s(16)
		end
		s
	end

	def send_completion!
		return unless SEND_EMAILS
     	UserMailer.setup_complete(self.id).deliver
    end

    def send_update!
    	return unless SEND_EMAILS
    	updates = status_updates
    	return unless updates.count > 0
    	updates = ["<h2>Dear #{name}</h2>
    		<br>
    		Please see the following reports from the positions of #{character.character_type} #{character.name}.<br>"] + 
    	updates.map do |report|
    		"<strong>#{report.position}</strong> - #{report.display_name}: #{report.summary}<br>"
    	end
    	UserMailer.status_update(self.id, updates).deliver
    	update_attributes!(status_email_sent_at: Time.now)
    end

    def send_character_killed!(character, reason)
    	return unless SEND_EMAILS
    	UserMailer.character_killed(self.id, character.id, reason).deliver
    end

    def status_updates
    	if status_email_sent_at
    		return ActionReport.for_user(self).since(status_email_sent_at)
    	else
    		return ActionReport.for_user(self)
    	end
    end

    def game
		self.character ? self.character.game : nil
	end

	def to_s
		self.game ? "#{name} (G#{game.id})" : "#{name}"
	end

	def forem_name
	  name
	end

	def forem_email
	  email
	end

	def character_name
		self.character ? self.character.name : name
	end

	def mail_email(object)
	    email
	end

	def setup_if_ready
		if !self.character_type.blank? && !setup_complete
			SetupUser.schedule(self)
		end
	end

	def set_colour_if_none
		if self.colour.nil?
			self.colour = User.random_colour
		end
	end

	def add_to_mailchimp
		begin
			Mailchimp::API.new(ENV['MAILCHIMP_API']).lists.subscribe(ENV['MAILCHIMP_LIST'],
			{
				"email" => self.email,
				"euid" => self.id,
				"leid" => self.id,
			},
			{"FNAME" => self.name})
		rescue Exception => e
			puts e 
		end
	end

	def as_json(options={})
		{
			name: name,
			character_type: character_type.blank? ? nil : character_type,
			game: setup_complete ? game : nil,
			character: setup_complete && character ? {
				id: character.id,
				name: character.name
			} : nil,
			colour: colour,
			uid: uid
		}
	end
end
