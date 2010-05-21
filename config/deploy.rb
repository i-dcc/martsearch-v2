set :application, "idcc_mouse_portal"
set :repository,  "git://github.com/dazoakley/martsearchr.git"
set :branch, "idcc_mouse_portal"
set :user, "do2"

set :scm, :git
set :deploy_via, :export
set :copy_compression, :bz2

set :keep_releases, 5
set :use_sudo, false

role :web, "localhost"
role :app, "localhost"
set :ssh_options, { :port => 10025 }

namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/log #{release_path}/log"
    run "ln -nfs #{shared_path}/cache #{release_path}/tmp/cache"
    run "ln -nfs #{shared_path}/solr_document_xmls #{release_path}/tmp/solr_document_xmls"
    run "ln -nfs #{shared_path}/pheno_images #{release_path}/public/images/pheno_images"
    run "ln -nfs #{shared_path}/pheno_abr #{release_path}/tmp/pheno_abr"
    run "ln -nfs #{shared_path}/pheno_overview.xls #{release_path}/public/pheno_overview.xls"
  end
  
  desc "Set the permissions of the filesystem so that others in the team can deploy"
  task :fix_perms do
    run "chgrp team87 #{release_path}/tmp"
    run "chmod 02775 #{release_path}"
  end
end

after "deploy:update_code", "deploy:symlink_shared"
after "deploy:symlink", "deploy:fix_perms"