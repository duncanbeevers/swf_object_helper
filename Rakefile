require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the swf_object_helper plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end
