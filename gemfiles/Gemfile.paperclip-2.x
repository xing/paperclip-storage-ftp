source "http://rubygems.org"

gemspec :path => '..'

gem "paperclip", "~>2.0"

group :test do
  gem "activerecord", "~>3.0"

  gem "sqlite3", :platforms => :ruby
  gem "activerecord-jdbcsqlite3-adapter", :platforms => :jruby
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'json'
end
