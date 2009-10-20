begin
  require 'shoulda'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  require 'shoulda'
end

require 'rcov/rcovtask'

desc "Analyze code coverage with tests"
Rcov::RcovTask.new do |t|
   t.libs << "test"
   t.test_files = FileList['test/test*.rb']
   t.verbose = true
   t.rcov_opts << "--no-color"
   t.rcov_opts << "--save coverage.info"
   t.rcov_opts << "-x ^/"
end
