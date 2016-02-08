source 'https://rubygems.org'
ruby "2.2.3"

gem 'rack-cors', :require => 'rack/cors'
gem 'rails', '4.2.4'
gem 'pg'
gem 'coffee-rails'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'bcrypt', '~> 3.1.7'
gem 'resque'
gem 'resque-status'
gem 'resque-scheduler'
gem 'lograge'
gem 'mandrill_mailer'
gem 'exception_notification'
gem 'bower-rails'
gem 'puma'
gem 'devise'
gem 'devise_token_auth'
gem 'clean_pagination'
gem 'forem', :github => "radar/forem", :branch => "rails4"
gem 'kaminari', '0.15.1'
gem 'forem-gfm_formatter'
gem 'forem-bootstrap', :github => "radar/forem-bootstrap"
gem 'mailboxer'
gem 'mailchimp-api', require: 'mailchimp'
gem 'rails_admin'
gem 'cancancan'

group :production do 
	gem 'rails_12factor'
	gem 'rails_serve_static_assets'
	gem 'rails_stdout_logging'
end

group :development, :test do
  gem 'byebug'
  gem 'rspec-rails'
  gem 'quiet_assets'
  gem 'simplecov', :require => false, :group => :test
end

group :development do
  gem 'web-console', '~> 2.0'
  gem 'spring'
end

