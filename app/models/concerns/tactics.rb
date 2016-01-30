module Tactics
	extend ActiveSupport::Concern

	ALL_TACTICS = ['Ambush','Flank','Skirmish','Swarm','Wall']

	TRAINING_FOR_TACTIC = {
		'Ambush' => 'Infiltration',
		'Flank' => 'Mobile',
		'Skirmish' => 'Guerrilla',
		'Swarm' => '',
		'Wall' => 'Discipline'
	}

	TACTIC_FOR_TRAINING = TRAINING_FOR_TACTIC.invert

	included do
		ALL_TACTICS.each do |tactic|
			define_method("training_#{tactic.downcase}?") do 
				self.tactics == tactic 
			end

			scope tactic.downcase.to_sym, -> { where({tactic: tactic})}
		end
	end
end