# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'lb-server'
set :repo_url, 'git@github.com:ackyla/lb-server.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/mnt/www/lb-server'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.rb}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp public/avatars}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :bundle_path, -> {shared_path.join('vendor/gems')}
set :bundle_without, %w{development test}.join(' ')

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc 'Runs rake ar:migrate if migrations are set'
  task :migrate do
    on roles(:db) do
      within release_path do
        execute :rake, "ar:migrate PADRINO_ENV=production"
      end
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
