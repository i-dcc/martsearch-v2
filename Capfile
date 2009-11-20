load 'deploy' if respond_to?(:namespace) # cap2 differentiator
require "rubygems"
require "railsless-deploy"
load "config/deploy"

set :stages, ["staging", "production"]
set :default_stage, "staging"
require "capistrano/ext/multistage"
require "config/deploy/natcmp.rb"
require "config/deploy/gitflow.rb"
