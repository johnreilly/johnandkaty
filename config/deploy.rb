set :application, "johnandkaty.org"
set :repository,  "git@github.com:johnreilly/johnandkaty.git"

set :scm, :git
set :git_enable_submodules, 1
set :branch, "johnandkaty"
set :user, "john"

default_run_options[:pty] = true  # Must be set for the password prompt from git to work
ssh_options[:forward_agent] = true
ssh_options[:port] = 2222

set :deploy_to, "/home/john/www/#{application}"

role :web, "67.207.134.112"
role :app, "67.207.134.112"
role :db, "67.207.134.112", :primary => true


namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

namespace :bundler do
  task :create_symlink, :roles => :app do
    shared_dir = File.join(shared_path, 'bundle')
    release_dir = File.join(current_release, '.bundle')
    run("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
  end
  
  task :bundle_new_release, :roles => :app do
    bundler.create_symlink
    run "cd #{release_path} && bundle install --without test"
  end
  
  task :lock, :roles => :app do
    run "cd #{current_release} && bundle lock;"
  end
  
  task :unlock, :roles => :app do
    run "cd #{current_release} && bundle unlock;"
  end
end


namespace :setup do

  desc "[internal] Updates the symlink for config files to the just deployed release."
  task :symlink, :except => { :no_release => true } do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end

end




# HOOKS
after "deploy:update_code" do
  bundler.bundle_new_release
end
after "deploy:finalize_update" do 
  setup.symlink
end