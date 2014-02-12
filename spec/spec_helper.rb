require "simplecov"
require "coveralls"

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter "spec"
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
end

require "paperclip/storage/ftp"

Paperclip.options[:log] = false

# https://github.com/thoughtbot/cocaine#jruby-caveat
Cocaine::CommandLine.runner = Cocaine::CommandLine::BackticksRunner.new
