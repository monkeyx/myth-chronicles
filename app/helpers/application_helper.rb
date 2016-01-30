module ApplicationHelper

	def help_tip(text)
		"<i class=\"fa fa-question\" uib-tooltip=\"#{text}\"></i>".html_safe
	end
end
