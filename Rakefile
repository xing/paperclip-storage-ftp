require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = "--color"
  t.rspec_opts += " --tag ~integration" if RUBY_PLATFORM == "java"
end

task :default => :spec
