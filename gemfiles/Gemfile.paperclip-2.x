source "http://rubygems.org"

gemspec :path => '..'

gem "paperclip", "~>2.0"

group :integration_test do
  gem "daemon_controller",  :platforms => :ruby
  gem "activerecord",       :platforms => :ruby
  gem "sqlite3",            :platforms => :ruby
end
