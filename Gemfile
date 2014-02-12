source 'https://rubygems.org'

# Specify your gem's dependencies in paperclip-storage-ftp.gemspec
gemspec

group :test do
  gem "sqlite3",                          :platforms => :ruby
  gem "activerecord-jdbcsqlite3-adapter", "1.3.0.beta2", :platforms => :jruby

  gem "coveralls", :require => false
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'json'
end
