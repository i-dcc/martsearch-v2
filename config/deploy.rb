set :application, "sanger_mouse_portal"
set :repository, "git://github.com/dazoakley/martsearchr.git"
set :branch, "sanger_mouse_portal"
set :user, "team87"

set :scm, :git
set :deploy_via, :export
set :copy_compression, :bz2

set :keep_releases, 5
set :use_sudo, false

role :web, "localhost"
role :app, "localhost"
set :ssh_options, { :port => 10025 }

namespace :deploy do
  desc "Restart Passenger"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,"tmp","restart.txt")}"
  end
  
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/log #{release_path}/log"
    run "ln -nfs #{shared_path}/cache #{release_path}/tmp/cache"
    run "ln -nfs #{release_path}/public #{shared_path}/htdocs/mouseportal"
    run "ln -nfs #{shared_path}/pheno_overview.xls #{release_path}/public/pheno_overview.xls"
    run "ln -nfs #{shared_path}/pheno_images #{release_path}/public/images/pheno_images"
    run "ln -nfs #{shared_path}/pheno_abr #{release_path}/tmp/pheno_abr"
  end
end

after "deploy:update_code", "deploy:symlink_shared"