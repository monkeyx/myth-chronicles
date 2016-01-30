class AllianceMember < ActiveRecord::Base
	include Temporal

	belongs_to :alliance
	belongs_to :member, class_name: 'Character'
	# publish_news
	# invite_member
	# accepted_invite
	# kick_member

	validate :validate_membership
	after_save :destroy_other_invitations!
	after_save :set_member_alliance!

	scope :for_character, ->(character) { where(member_id: character.id )}
	scope :for_alliance, ->(alliance) { where(alliance_id: alliance.id )}
	scope :not_alliance, ->(alliance) { where(["alliance_id <> ?", alliance.id])}
	scope :accepted, -> { where(accepted_invite: true)}
	scope :pending, -> { where(accepted_invite: false)}

	def accept!
		transaction do
			self.member.alliance = self.alliance
			self.member.save!
			self.accepted_invite = true
			self.game_time = self.member.game.game_time
			save!
		end
	end
	
	def validate_membership
		if new_record?
			errors.add(:member_id, 'already a member') if AllianceMember.for_alliance(self.alliance).for_character(self.member).accepted.count > 0
			errors.add(:member_id, 'already invited') if AllianceMember.for_alliance(self.alliance).for_character(self.member).pending.count > 0
			errors.add(:alliance_id, 'invalid - already part of an alliance') if AllianceMember.for_character(self.member).accepted.count > 0
		end
	end

	def destroy_other_invitations!
		AllianceMember.for_character(self.member).not_alliance(self.alliance).destroy_all if self.accepted_invite
	end

	def set_member_alliance!
		self.member.update_attributes!(alliance_id: self.alliance_id) if self.accepted_invite
	end

	def score
		return 0 unless self.accepted_invite
		s = 1
		s += 5 if self.alliance.leader && self.alliance.leader.id == self.member.id
		s += 2 if self.kick_member
		s += 1 if self.publish_news
		s += 1 if self.invite_member
		return s
	end

	def to_s
		"#{member}"
	end

	def as_json(options={})
		{
			id: member.id,
			name: member.name,
			joined: game_time,
			rights: {
				news: publish_news,
				invite: invite_member,
				kick: kick_member
			}
		}
	end
end
