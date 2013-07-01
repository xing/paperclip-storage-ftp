source "http://rubygems.org"

gemspec :path => '..'

gem "paperclip", "~>3.0"

group :test do
  gem "sqlite3",                          :platforms => :ruby
  gem "activerecord-jdbcsqlite3-adapter", "1.3.0.beta2", :platforms => :jruby
end
