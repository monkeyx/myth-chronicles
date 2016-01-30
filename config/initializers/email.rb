EMAIL_DEFAULT_FROM = "Myth Chronicles <gm@mythchronicles.com"
EMAIL_DEFAULT_REPLY = "Myth Chronicles <gm@mythchronicles.com>"

unless Rails.env.production?
	EMAIL_BASE_HOST = "localhost:5000"
	EMAIL_HOME_URL = "http://#{EMAIL_BASE_HOST}"
else
	EMAIL_BASE_HOST = "mythchronicles.com"
	EMAIL_HOME_URL = "http://www.#{EMAIL_BASE_HOST}"
end

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = EMAIL_BASE_HOST
ActionMailer::Base.raise_delivery_errors = true

ActionMailer::Base.smtp_settings = {
  :address  => "smtp.mandrillapp.com",
  :port  => 587, 
  :user_name => ENV['SMTP_USERNAME'],
  :password => ENV['SMTP_PASSWORD'],
  :domain  => "mythchronicles.com",
  :enable_starttls_auto => true
}

MandrillMailer.configure do |config|
  config.api_key = ENV['SMTP_PASSWORD']
end