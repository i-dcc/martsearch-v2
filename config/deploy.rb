set :application, "sanger_mouse_portal"
set :repository, "git://github.com/dazoakley/martsearchr.git"
set :branch, "sanger_mouse_portal"
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
    run "ln -nfs #{release_path}/public #{shared_path}/htdocs/mouseportal"
    run "ln -nfs #{shared_path}/pheno_images #{release_path}/public/images/pheno_images"
    run "ln -nfs #{shared_path}/pheno_abr #{release_path}/tmp/pheno_abr"
  end
  
  desc "Regenerate the Sanger Phenotyping heatmap upon release."
  task :generate_heatmap do
    brave_new_world_env = {
      :PATH     => "/software/team87/brave_new_world/bin:/software/perl-5.8.8/bin:/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/bin:/usr/bin:$PATH",
      :PERL5LIB => "/software/team87/brave_new_world/lib/perl5:/software/team87/brave_new_world/lib/perl5/x86_64-linux-thread-multi",
      :CONF_DIR => "/software/team87/brave_new_world/conf",
      :LOG_DIR  => "/software/team87/brave_new_world/logs/cron"
    }
    
    run "htgt-env.pl --live perl #{release_path}/config/datasets/sanger-phenotyping/generate-spreadsheet.pl", :env => brave_new_world_env
  end
  
  desc "Set the permissions of the filesystem so that others in the team can deploy"
  task :fix_perms do
    run "chgrp team87 #{release_path}/tmp"
    run "chmod 02775 #{release_path}"
  end
end

after "deploy:update_code", "deploy:symlink_shared"
after "deploy:symlink", "deploy:generate_heatmap", "deploy:fix_perms"