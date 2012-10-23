source "http://rubygems.org"

gemspec :path => '..'

gem "paperclip", "~>3.0"

group :test do
  gem "sqlite3", :platforms => :ruby
end
