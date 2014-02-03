source "http://rubygems.org"

gemspec :path => '..'

gem "paperclip", "~>4.0"

group :test do
  gem "sqlite3", :platforms => :ruby
  gem "activerecord-jdbcsqlite3-adapter", :platforms => :jruby
end
