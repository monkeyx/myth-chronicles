class BaseAction

	def self.status(action_id)
		hash = Resque::Plugins::Status::Hash.get(action_id)
		return {
			completed: hash.completed?,
			failed: hash.failed?,
			message: hash.message,
			options: hash.options
		}
	end

	def self.cancel(action_id)
		hash = Resque::Plugins::Status::Hash.get(action_id)
		if hash && !(hash.completed? || hash.failed?)
			Resque::Plugins::Status::Hash.kill(action_id)
			return true
		end
		false
	end

	class QueuedAction
		include Resque::Plugins::Status
		
		@queue = :action

		def perform
			action_class = Object.const_get(options['action_class'])
			user = User.where(id: options['user_id']).first
			position = Object.const_get(options['position_type']).where(id: options['position_id']).first
			params = options['params']
			action = action_class.new(user, position, params)
			tick("#{action_class} on #{position} starting")
			success = action.run!
			if success
				completed(action.report_to_s)
			else
				failed(action.errors_to_s)
			end
		end
	end

	FREE_ACTION = 0
	FAST_ACTION = 1
	NORMAL_ACTION = 2
	SLOW_ACTION = 4

	attr_accessor :user, :position, :params, :errors, :report_entries, :skip_action_report

	def initialize(user, position, params)
		self.user = user 
		self.position = position
		self.params = params 
		self.errors = []
		self.report_entries = []
	end

	def validate
		unless valid_positions.include?(position.class)
			self.errors << {position_type: 'Invalid position for this action'}
		end
		unless valid_subtype == :any || valid_subtype.include?(position.subtype)
			self.errors << {position_type: 'Invalid position for this action'}
		end

		self.parameters.keys.each do |param_name|
			param_required = self.parameters[param_name][:required]
			param_type = self.parameters[param_name][:type]
			param_value = self.params[param_name.to_s]
			param_display_name = param_name.to_s.gsub('id','').gsub('_', ' ').capitalize
			if param_value.blank? && param_required
				self.errors << {param_name => "#{param_display_name} is required"}
			else
				case param_type
				when 'integer'
					param_value.to_i rescue self.errors << {param_name => "#{param_display_name} is not a number"}
				when 'boolean'
					unless param_value.to_s.blank? || param_value.to_s.downcase == 'true' || param_value.to_s.downcase == 'false'
						self.errors << {param_name => "#{param_display_name} is not yes or no"}
					end
				when 'string'
				end
			end
		end
		self.errors.count < 1
	end

	def enqueue
		QueuedAction.create(action_class: self.class.name, user_id: user.id, position_type: position.class.name, position_id: position.id, params: params)
	end

	def run!
		unless validate
			report = ActionReport.new(position: self.position.position, name: self.class.name)
			report.summary = errors_to_s
			report.game_time = position.game.game_time
			report.save!
			return false 
		end
		success = false
		self.skip_action_report = false
		if user && user.confirmed? && position
			if user.character && position.belongs_to?(user.character)
				Rails.logger.info "#{position.class} #{position.id}: Action : #{self.class.name} : START"
				begin
					position.transaction do
						success = self.transaction!
						if success
							user.character.use_action_points!(self.action_point_cost) 
						end
						Rails.logger.info "#{position.class} #{position.id}: Action : #{self.class.name} : FINISH (Success: #{success})"
					end
				rescue => e
					success = false
					unless e.to_s == "Insufficient Action Points"
						add_exception(e)
						Rails.logger.error "#{position.class} #{position.id}: Action : #{self.class.name} : ERROR: #{e}" 
						Rails.logger.error e.backtrace
					else
						add_error('insufficient_action_points')
						Rails.logger.error "#{position.class} #{position.id}: Action : #{self.class.name} : ERROR: Insufficient Action Points #{action_point_cost}"
					end
				end
			else
				self.skip_action_report = true
				Rails.logger.error "#{position.class} #{position.id}: Action : #{self.class.name} : Unauthorized"
			end
		else
			self.skip_action_report = true
			Rails.logger.error "#{self.class.name} : ERROR: Invalid - User: #{user} - Position: #{position} - Params: #{params}"
		end
		report = nil
		unless self.skip_action_report
			summary = errors_to_s
			summary = report_to_s if summary.blank?
			raise "No action report defined for #{self.class}" if summary.blank?
			ActionReport.add_report!(self.position, self.class.name, summary)
		end
		Rails.logger.info "#{self.class.name} : SUCCESS? #{success} : #{report}"
		return success
	end

	# Action report
	def report_to_s
		self.report_entries.join("\n")
	end

	def add_report(variables={}, subkey=nil)
		variables.merge!({position_type: position.class.name, position_id: position.id, position_name: position.name, location: position.location})
		unless subkey
			self.report_entries << I18n.translate("actions.#{self.class.name}", variables)
		else
			self.report_entries << I18n.translate("actions.#{self.class.name}.#{subkey}", variables)
		end
	end

	# Helper
	def is_true?(param_key)
		!params[param_key].blank? && params[param_key].to_s.downcase == 'true'
	end

	def is_false?(param_key)
		!params[param_key].blank? && params[param_key].to_s.downcase == 'false'
	end

	# Errors and exception reporting

	def errors_to_s
		err = []
		self.errors.each do |error|
			if error.respond_to?(:keys)
				error.keys.each do |key|
					err << "#{error[key]}"
				end
			else
				err << error.to_s
			end
		end
		err.join(', ')
	end

	def set_errors(errors)
		self.errors = self.errors + errors.full_messages
	end

	def add_error(key)
		value = I18n.translate("errors.#{key}", {position_type: position.class.name, position_id: position.id, position_name: position.name, location: position.location})
		Rails.logger.error(value)
		self.errors << {key => value}
	end

	def add_exception(e)
		Rails.logger.error(e.to_s + ": " + e.backtrace.join("\n"))
		self.errors << {:exception => e.to_s}
	end

	# TO BE OVERRIDEN

	def valid_positions
		[Character, Settlement, Army]
	end

	def valid_subtype
		:any
	end

	def parameters
		{}
	end

	def transaction!(user, position, params)
		raise "#{self.class.name} has no transaction defined!"
	end

	def action_point_cost
		raise "#{self.class.name} has no action point cost defined!"
	end
	
	
end