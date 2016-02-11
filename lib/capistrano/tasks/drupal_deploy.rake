# Load default values the capistrano 3.x way.
# See https://github.com/capistrano/capistrano/pull/605
namespace :load do
  task :defaults do
    set :composer_download_url, "https://getcomposer.org/installer"
    set :install_composer, true
    set :install_drush, true
    set :app_path, 'app'
    if fetch(:install_drush)
      set :drush,  "#{fetch(:shared_path)}/drush/drush"
    end
  end
end


namespace :deploy do

  desc 'Deploy your project and do an updatedb, feature revert, cache clear...'
  task :full do
    :deploy

    if fetch(:install_composer)
      invoke "composer:install_executable"
    end

    if fetch(:install_drush)
      invoke "drush:install"
    end

    invoke "drupal:site_offline"
    invoke "drupal:update:updatedb"
    invoke "drupal:feature_revert"
    invoke "drupal:site_online"
    invoke "drupal:cache:clear"
  end
end

# Specific Drupal tasks
namespace :drupal do

  desc 'Run any drush command'
  task :drush do
    ask(:drush_command, "Drush command you want to run (eg. 'cache-clear css-js'). Type 'help' to have a list of avaible drush commands.")
    command = fetch(:drush_command)
    on roles(:app) do
      within release_path.join(fetch(:app_path)) do
        execute :drush, command
      end
    end
  end

  desc 'Show logs'
  task :logs do
    on roles(:app) do
      within release_path.join(fetch(:app_path)) do
        execute :drush, 'watchdog-show  --tail'
      end
    end
  end

  desc 'Provides information about things that may be wrong in your Drupal installation, if any.'
  task :requirements do
    on roles(:app) do
      within release_path.join(fetch(:app_path)) do
        execute :drush, 'core-requirements'
      end
    end
  end

  desc 'Open an interactive shell on a Drupal site.'
  task :cli do
    on roles(:app) do
      within release_path.join(fetch(:app_path)) do
        execute :drush, 'core-cli'
      end
    end
  end

  desc 'Set the site offline'
  task :site_offline do
    on roles(:app) do
      within release_path.join(fetch(:app_path)) do
        execute :drush, 'vset maintenance_mode 1 -y'
      end
    end
  end

  desc 'Set the site online'
  task :site_online do
    on roles(:app) do
      within release_path.join(fetch(:app_path)) do
        execute :drush, 'vset maintenance_mode 0 -y'
      end
    end
  end

  desc 'Revert feature'
  task :feature_revert do
    on roles(:app) do
      within release_path.join(fetch(:app_path)) do
        execute :drush, 'features-revert-all -y'
      end
    end
  end

  desc 'Backup the database using backup and migrate'
  task :backupdb do
    on roles(:app) do
      within release_path.join(fetch(:app_path)) do
        execute :drush, 'bam-backup'
      end
    end
  end

  namespace :update do
    desc 'List any pending database updates.'
    task :updatedb_status do
      on roles(:app) do
        within release_path.join(fetch(:app_path)) do
          execute :drush, 'updatedb-status'
        end
      end
    end

    desc 'Apply any database updates required (as with running update.php).'
    task :updatedb do
      on roles(:app) do
        within release_path.join(fetch(:app_path)) do
          execute :drush, 'updatedb -y'
        end
      end
    end

    desc 'Show a report of available minor updates to Drupal core and contrib projects.'
    task :pm_updatestatus do
      on roles(:app) do
        within release_path.join(fetch(:app_path)) do
          execute :drush, 'pm-updatestatus'
        end
      end
    end
  end

  namespace :cache do
    desc 'Clear all caches'
    task :clear do
      on roles(:app) do
        within release_path.join(fetch(:app_path)) do
          execute :drush, 'cache-clear all'
        end
      end
    end
  end

end

namespace :files do

  desc "Download drupal sites files (from remote to local)"
  task :download do
    run_locally do 
      on release_roles :app do |server|
        ask(:answer, "Do you really want to download the files on the server to your local files? Nothings will be deleted but files can be ovewrite. (y/N)");
        if fetch(:answer) == 'y' then
          remote_files_dir = "#{shared_path}/#{(fetch(:app_path))}/sites/default/files/"
          local_files_dir = "#{(fetch(:app_path))}/sites/default/files/"
          system("rsync --recursive --times --rsh=ssh --human-readable --progress --exclude='.*' --exclude='css' --exclude='js' #{server.user}@#{server.hostname}:#{remote_files_dir} #{local_files_dir}")
        end
      end
    end
  end

  desc "Upload drupal sites files (from local to remote)"
  task :upload do
    on release_roles :app do |server|
      ask(:answer, "Do you really want to upload your local files to the server? Nothings will be deleted but files can be ovewrite. (y/N)");
      if fetch(:answer) == 'y' then
        remote_files_dir = "#{shared_path}/#{(fetch(:app_path))}/sites/default/files/"
        local_files_dir = "#{(fetch(:app_path))}/sites/default/files/"
        system("rsync --recursive --times --rsh=ssh --human-readable --progress --exclude='.*' --exclude='css' --exclude='js' #{local_files_dir} #{server.user}@#{server.hostname}:#{remote_files_dir}")
      end
    end
  end

  desc "Fix drupal upload files folder permission"
  task :fix_permission do
    on roles(:app) do
      remote_files_dir = "#{shared_path}/#{(fetch(:app_path))}/sites/default/files/*"
      execute :chgrp, "-R www-data #{remote_files_dir}"
      execute :chmod, "-R g+w #{remote_files_dir}"
    end
  end

end


# Install drush
namespace :drush do
  desc "Install Drush"
  task :install do
    on roles(:app) do
      within shared_path do
        execute :composer, 'require drush/drush:~6.0.0'
      end
    end
  end
end
