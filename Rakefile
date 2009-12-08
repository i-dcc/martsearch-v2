require 'metric_fu'

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
    "active_support",
    "will_paginate",
    "metric_fu",
    "chronic",
    "shoulda",
    "test-unit"
  ]
  dependencies.each do |gem_name|
    puts "#{gem_name}"
    system "gem install #{gem_name}"
  end
end

# Load rake tasks from the tasks directory
Dir["tasks/*.rake"].each { |t| load t }

MetricFu::Configuration.run do |config| 
  config.metrics  = [:churn, :saikuro, :flog, :flay, :reek, :roodi, :rcov]
  config.graphs   = [:flog, :flay, :reek, :roodi, :rcov]
  config.reek     = { :dirs_to_reek => ["lib"] }
  config.rcov     = { 
                      :test_files => ["test/test_*.rb"],
                      :rcov_opts => [
                        "--sort coverage", 
                        "--no-html", 
                        "--text-coverage",
                        "--no-color",
                        "--profile",
                        "--exclude /gems/,/Library/,spec"
                      ]
                    }
end