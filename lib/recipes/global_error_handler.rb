module GlobalErrorHandler
  class Capistrano
    def self.load_into(config)
      config.load do
        namespace :global_error_handler do
          desc 'Subscribe to expiration'
          task :subscribe do
            run %Q{cd #{latest_release} && RAILS_ENV=#{rails_env} nohup rake global_error_handler:subscribe_to_expired >/dev/null 2>&1 & sleep 2}
          end

          desc 'Unsubscribe from expiration'
          task :unsubscribe do
            run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} global_error_handler:unsubscribe_from_expired}
          end

          desc 'Update Subscription to expiration'
          task :update_subscription do
            unsubscribe
            subscribe
          end
          after 'deploy:restart', 'global_error_handler:update_subscription'
        end
      end
    end
  end
end
