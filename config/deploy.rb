set :application, "martsearch"
set :repository,  "git://github.com/dazoakley/martsearchr.git"
set :branch, "master"
set :user, "do2"

set :scm, :git
set :deploy_via, :export
set :copy_compression, :bz2

set :keep_releases, 5
set :use_sudo, false

role :web, "localhost"
role :app, "localhost"
set :ssh_options, { :port => 10027 }


namespace :deploy do
  desc "Restart Passenger"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,"tmp","restart.txt")}"
  end
  
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/log #{release_path}/log"
    run "ln -nfs #{shared_path}/cache #{release_path}/tmp/cache"
    run "ln -nfs #{shared_path}/solr_document_xmls #{release_path}/tmp/solr_document_xmls"
    run "ln -nfs #{shared_path}/ols_database.yml #{release_path}/config/ols_database.yml"
  end
end

after "deploy:update_code", "deploy:symlink_shared"