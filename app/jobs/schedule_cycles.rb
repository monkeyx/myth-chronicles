class ScheduleCycles

	@queue = :scheduler

	def self.perform
		Game.due_cycle.each do |game|
            CycleGame.schedule(game)
        end
	end

end