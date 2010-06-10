desc 'Default task: run all tests'
task :default => [:test]

desc "Install gems that this app depends on. May need to be run with sudo."
task :install_deps do
  dependencies = [
    "sinatra",
    "rack-contrib",
    "json",
    "erubis",
    "biomart",
    "rdiscount",
    "mail",
    "activesupport",
    "will_paginate",
    "shoulda",
    "test-unit",
    "rack-test",
    "builder",
    "rsolr",
    "yui-compressor",
    "rubytree",
    "sequel",
    "libxml-ruby"
  ]
  dependencies.each do |gem_name|
    puts "#{gem_name}"
    system "gem install #{gem_name}"
  end
end

# Load rake tasks from the tasks directory
Dir["#{File.dirname(__FILE__)}/tasks/*.task"].each { |t| load t }
