module Training
	extend ActiveSupport::Concern

	ALL_TRAINING = ['','Archery','Discipline','Armoured','Infiltration','Machinery','Mobile','Reconnaissance','Guerrilla']

	included do
		ALL_TRAINING.each do |training|
			define_method("training_#{training.downcase}?") do 
				self.training == training
			end

			scope training.downcase.to_sym, -> { where({training: training})}
		end
	end
end