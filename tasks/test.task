begin
  require 'shoulda'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  require 'shoulda'
end

require 'rake/testtask'

desc "Run the test suite under /test"
Rake::TestTask.new do |t|
   t.libs << "test"
   t.test_files = FileList['test/test*.rb']
   t.verbose = true
end
