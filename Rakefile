begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc 'Default: run specs.'
task :default => :ci

desc 'Run specs (without .env file)'
task :ci do
  # Manage .env file around specs.
  FileUtils.mv '.env', '.env_bak', force: true
  Rake::Task['spec'].invoke
  FileUtils.mv '.env_bak', '.env', force: true
end
