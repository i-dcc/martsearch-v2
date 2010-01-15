desc 'Default task: run all tests'
task :default => [:test]

desc "Install gems that this app depends on. May need to be run with sudo."
task :install_deps do
  dependencies = [
    "sinatra",
    "rack-contrib",
    "json",
    "biomart",
    "rdiscount",
    "mail",
    "activesupport",
    "will_paginate",
    "chronic",
    "shoulda",
    "test-unit",
    "rack-test",
    "builder",
    "rsolr"
  ]
  dependencies.each do |gem_name|
    puts "#{gem_name}"
    system "gem install #{gem_name}"
  end
end

# Load rake tasks from the tasks directory
Dir["#{File.dirname(__FILE__)}/tasks/*.task"].each { |t| load t }
