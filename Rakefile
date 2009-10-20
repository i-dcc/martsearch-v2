desc 'Default task: run all tests'
task :default => [:test]

desc "Install gems that this app depends on. May need to be run with sudo."
task :install_deps do
  dependencies = [
    "sinatra",
    "json"
  ]
  dependencies.each do |gem_name|
    puts "#{gem_name}"
    system "gem install #{gem_name}"
  end
end

# Load rake tasks from the tasks directory
Dir["tasks/**/*.rake"].each { |t| load t }

