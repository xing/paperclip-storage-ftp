begin
  require "coveralls"
  Coveralls.wear!
rescue LoadError
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end

  config.mock_with :rspec do |c|
    c.syntax = [:expect, :should]
  end
end

require "paperclip/storage/ftp"

Paperclip.options[:log] = false
