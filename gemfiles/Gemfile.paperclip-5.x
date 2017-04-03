source "http://rubygems.org"

gemspec :path => '..'

gem "paperclip", "~>5.0"

group :test do
  gem "sqlite3"
  gem "coveralls", :require => false
end
