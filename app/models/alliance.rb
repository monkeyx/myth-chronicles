class Alliance < ActiveRecord::Base
	include Temporal

	validates :name, length: {in: 1..50}
	belongs_to :leader, class_name: 'Character'

	has_many :alliance_members

	after_save :set_leader_alliance!

	scope :in_game, ->(game) { where(["leader_id IN (?)", Character.in_game(game).map{|c| c.id }])}

	def members_by_rank
		self.alliance_members.to_a.sort{|a,b| b.score <=> a.score }
	end

	def can_invite?(character)
		return false unless character
		return true if self.leader_id == character.id
		m = member?(character)
		m.nil? ? false : m.invite_member
	end

	def can_kick?(character)
		return false unless character
		return true if self.leader_id == character.id
		m = member?(character)
		m.nil? ? false : m.kick_member
	end

	def can_publish_news?(character)
		return false unless character
		return true if self.leader_id == character.id
		m = member?(character)
		m.nil? ? false : m.publish_news
	end

	def give_invite_rights!(character)
		raise "Invalid character" unless character
		return if self.leader_id == character.id
		raise "Invalid character" unless (m = member?(character))
		m.update_attributes!(invite_member: true)
	end

	def revoke_invite_rights!(character)
		raise "Invalid character" unless character
		return if self.leader_id == character.id
		raise "Invalid character" unless (m = member?(character))
		m.update_attributes!(invite_member: false)
	end

	def give_kick_rights!(character)
		raise "Invalid character" unless character
		return if self.leader_id == character.id
		raise "Invalid character" unless (m = member?(character))
		m.update_attributes!(kick_member: true)
	end

	def revoke_kick_rights!(character)
		raise "Invalid character" unless character
		return if self.leader_id == character.id
		raise "Invalid character" unless (m = member?(character))
		m.update_attributes!(kick_member: false)
	end

	def give_publish_news_rights!(character)
		raise "Invalid character" unless character
		return if self.leader_id == character.id
		raise "Invalid character" unless (m = member?(character))
		m.update_attributes!(publish_news: true)
	end

	def revoke_publish_news_rights!(character)
		raise "Invalid character" unless character
		return if self.leader_id == character.id
		raise "Invalid character" unless (m = member?(character))
		m.update_attributes!(publish_news: false)
	end

	def leader?(character)
		character && self.leader_id == character.id
	end

	def invited?(character)
		AllianceMember.for_alliance(self).for_character(character).pending.first
	end

	def member?(character)
		AllianceMember.for_alliance(self).for_character(character).accepted.first
	end

	def join!(character)
		AllianceMember.create!(alliance: self, member: character, accepted_invite: true, game_time: character.game.game_time)
	end

	def invite!(character)
		AllianceMember.create!(alliance: self, member: character, accepted_invite: false, game_time: character.game.game_time)
	end

	def kick!(character)
		raise "Cannot kick leader" if leader?(character)
		m = member?(character)
		if m
			transaction do
				m.destroy
				character.alliance = nil
				character.save!
			end
		end
	end

	def leave!(character)
		m = member?(character)
		if m
			transaction do
				m.destroy
				character.alliance = nil
				character.save!
				if self.leader.id == character.id
					next_leader = members_by_rank.select{|m| m.member.lord? }.first
					unless next_leader
						destroy
					else
						self.leader = next_leader.member
						save!
					end
				end
			end
		end
	end

	def set_leader_alliance!
		self.leader.update_attributes!(alliance_id: self.id)
		unless member?(self.leader)
			AllianceMember.create!(alliance: self, member: self.leader, accepted_invite: true, kick_member: true, publish_news: true, invite_member: true, game_time: self.leader.game.game_time)
		end
	end

	def settlements
		Settlement.in_alliance(self)
	end

	def to_s
		"#{name} (#{id})"
	end

	def as_json(options={})
		{
			id: id,
			leader: {
				id: leader.id,
				name: leader.name
			},
			members: alliance_members.accepted.where(["member_id <> ?", leader.id]),
			founded: game_time,
			name: name
		}
	end
end
