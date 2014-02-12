source "http://rubygems.org"

gemspec :path => '..'

gem "paperclip", "~>3.0"

group :test do
  gem "sqlite3", :platforms => :ruby
  gem "activerecord-jdbcsqlite3-adapter", :platforms => :jruby

  gem "coveralls", :require => false
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'json'
end
