#!/usr/bin/env rake
require 'bundler/gem_tasks'

begin
  require 'rubocop/rake_task'
  require 'rspec/core/rake_task'

  desc 'Build Documentation'
  YARD::Rake::YardocTask.new(:documentation) do |t|
    t.files = DOC_FILES
    t.options = ['-p', 'doc_config/templates']
  end

  desc 'Run Rubocop'
  RuboCop::RakeTask.new(:rubocop)

  desc 'Run Unit Tests'
  RSpec::Core::RakeTask.new(:test) do |t|
    t.pattern = FileList["spec/**/*_spec.rb"]
  end

  task default: [:rubocop, :test]
rescue LoadError
  puts 'Load Error - No RSpec'
end
