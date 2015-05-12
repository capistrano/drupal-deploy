# Capistrano Drupal Deploy

This gem provides a number of tasks which are useful for deploying Drupal 7 projects with [Capistrano 3](http://capistranorb.com/) and the help of drush. This is a short doc to help you deploy a drupal projet. To know more about capistrano read their documentation on [Capistrano 3](http://capistranorb.com/).


## Installation
[gems](http://rubygems.org) must be installed on your system first.

Your application Gemfile need those lines:

```ruby
source 'https://rubygems.org'
group :development do
    gem 'capistrano-drupal-deploy', '~> 0.0.2' , :path => "/Users/simon/bin/capistrano-drupal-deploy/"
end
```

And then execute:

    $ bundle
    $ bundle exec cap install

Or install it yourself as:

    $ gem install capistrano-drupal-deploy
    $ cap install

## Usage	

Require the module in your `Capfile`:

```ruby
require 'capistrano/drupal-deploy'
# Composer is needed to install drush on the server
require 'capistrano/composer'
```

### Configuration

Edit `config/deploy.rb` to set the global parameters. You should at least edit your app_name and your repo_url.

```ruby
 set :application, 'my app name'
 set :repo_url, 'git@example.com:me/my_repo.git'
```

*Capistrano drupal deploy* makes the following configuration variables available

```ruby
# Path to the drupal directory, default to app.
set :app_path,        "app"
```

Drupal need settings.php and, files and private-files shared accross deploy

```ruby
# Link file settings.php
set :linked_files, fetch(:linked_files, []).push('app/sites/default/settings.php')

# Link dirs files and private-files
set :linked_dirs, fetch(:linked_dirs, []).push('app/sites/default/files', 'private-files')
```


Composer and drush need to be mapped

```ruby
# Remove default composer install task on deploy:updated
Rake::Task['deploy:updated'].prerequisites.delete('composer:install')

# Map composer and drush commands
# NOTE: If stage have different deploy_to
# you have to copy those line for each <stage_name>.rb
# See https://github.com/capistrano/composer/issues/22
SSHKit.config.command_map[:composer] = "#{shared_path.join("composer.phar")}"
SSHKit.config.command_map[:drush] = "#{shared_path.join("vendor/bin/drush")}"
```
	
Configure each stage in config/deploy/<stage_name>.rb. Overwrite global settings if needed.

```ruby
# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

# server 'example.com', user: 'deploy', roles: %w{app db web}, my_property: :my_value

# overwrite deploy_to
set :deploy_to, '/var/www/stage_name/my_app'

# set a branch for this release
set :branch, 'dev'
```


	
For more information about configuration http://capistranorb.com/


## Deployement

Run deploy

	$ cap <stage_name> deploy

After a couple a command, it will fail with this error:

	Finished in 0.067 seconds with exit status 1 (failed).
	ERROR linked file /var/www/stage_name/my_app/shared/app/sites/default/settings.php does not exist on staging.mysite.com
	
As expected, Capistrano has been told to link your settings.php file, but it can’t find it on the server where it expects. We need to manually upload that file now. If we look at the app directory on our server, it now contains two folders releases and shared. Inside of the shared directory you will find a app/sites/default directory. You will need to create your settings.php file into that directory.

On the server your webserver user (eg. www-data) need to has the right to write in

	/var/www/stage_name/my_app/shared/app/sites/default/files
	/var/www/stage_name/my_app/shared/private-files

Once this is done, try and deploy again. If everything goes well, Capistrano will clone your app from your repositroy and work the rest.

Now, every time you want to deploy your app

	$ cap deploy

Some command use drush. To install drush on your server

	$ cap composer:install_executable
	$ cap drush:install


If you want to deploy your app and also revert features, clear cache

	$ cap deploy:full
	
And if some troubles occur, juste launch the rollback command to return to the previous release.

	$ cap deploy:rollback


You should then be able to proceed as you would usually, you may want to familiarise yourself with the truncated list of tasks, you can get a full list with:

    $ cap -T
    
This show a list of all avaible commands:

    
	cap composer:install               # Install the project dependencies via Composer
	cap composer:install_executable    # Installs composer.phar to the shared directory
	cap composer:self_update           # Run the self-update command for composer.phar
	cap deploy                         # Deploy a new release
	cap deploy:check                   # Check required files and directories exist
	cap deploy:check:directories       # Check shared and release directories exist
	cap deploy:check:linked_dirs       # Check directories to be linked exist in shared
	cap deploy:check:linked_files      # Check files to be linked exist in shared
	cap deploy:check:make_linked_dirs  # Check directories of files to be linked exist in shared
	cap deploy:cleanup                 # Clean up old releases
	cap deploy:cleanup_rollback        # Remove and archive rolled-back release
	cap deploy:finished                # Finished
	cap deploy:finishing               # Finish the deployment, clean up server(s)
	cap deploy:finishing_rollback      # Finish the rollback, clean up server(s)
	cap deploy:full                    # Deploy your project and do an updatedb, feature revert, cache clear..
	cap deploy:log_revision            # Log details of the deploy
	cap deploy:published               # Published
	cap deploy:publishing              # Publish the release
	cap deploy:restart                 # Restart application
	cap deploy:revert_release          # Revert to previous release timestamp
	cap deploy:reverted                # Reverted
	cap deploy:reverting               # Revert server(s) to previous release
	cap deploy:rollback                # Rollback to previous release
	cap deploy:set_current_revision    # Place a REVISION file with the current revision SHA in the current release path
	cap deploy:started                 # Started
	cap deploy:starting                # Start a deployment, make sure server(s) ready
	cap deploy:symlink:linked_dirs     # Symlink linked directories
	cap deploy:symlink:linked_files    # Symlink linked files
	cap deploy:symlink:release         # Symlink release to current
	cap deploy:symlink:shared          # Symlink files and directories from shared to release
	cap deploy:updated                 # Updated
	cap deploy:updating                # Update server(s) by setting up a new release
	cap drupal:backupdb                # Backup the database using backup and migrate
	cap drupal:cache:clear             # Clear all caches
	cap drupal:cli                     # Open an interactive shell on a Drupal site
	cap drupal:drush                   # Run any drush command
	cap drupal:feature_revert          # Revert feature
	cap drupal:logs                    # Show logs
	cap drupal:requirements            # Provides information about things that may be wrong in your Drupal installation, if any
	cap drupal:site_offline            # Set the site offline
	cap drupal:site_online             # Set the site online
	cap drupal:update:pm_updatestatus  # Show a report of available minor updates to Drupal core and contrib projects
	cap drupal:update:updatedb         # Apply any database updates required (as with running update.php)
	cap drupal:update:updatedb_status  # List any pending database updates
	cap drush:install                  # Install Drush
	cap files:download                 # Download drupal sites files (from remote to local)
	cap files:upload                   # Upload drupal sites files (from local to remote)
	cap install                        # Install Capistrano, cap install STAGES=staging,production


## Infos

Inspired by [capistrano-drupal](https://github.com/previousnext/capistrano-drupal) and [capdrupal](https://github.com/antistatique/capdrupal)
