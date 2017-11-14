begin
  require 'rspec/core/rake_task'
  require 'rubocop/rake_task'
  RSpec::Core::RakeTask.new(:rspec) do |t|
    t.rspec_opts = %w[-I lib/]
  end
  # Code quality
  # Linter
  RuboCop::RakeTask.new(:lint) do |t|
    t.options = %w[-S -D]
  end
rescue LoadError
  task(:rspec)
  task(:lint)
end

desc 'Run :check'
task :default => :check

desc 'run tests'
task :test => :rspec

desc 'Run lint and tests'
task :check => %i[test lint]

desc 'Build yard doc'
task :doc do
  puts `yard --doc`
end
