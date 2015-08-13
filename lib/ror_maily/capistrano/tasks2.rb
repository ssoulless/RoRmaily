Capistrano::Configuration.instance.load do
	namespace :ror_maily do
		desc "Stop ror_maily"
		task :stop, roles: :app do
			run "cd #{current_path}; bundle exec ror_maily --stop"
		end

		desc "Start ror_maily"
		task :start, roles: :app do
			run "cd #{current_path}; RAILS_ENV=#{rails_env} bundle exec ror_maily --start" 
		end

		desc "Restart ror_maily"
		task :restart, roles: :app do
			run "cd #{current_path}; RAILS_ENV=#{rails_env} bundle exec ror_maily --restart" 
		end
	end

	after 'deploy', 'ror_maily:restart'
end
