module GlobalErrorHandler
  class Capistrano #:nodoc:
    def self.load_into(config)
      config.load do
        namespace :global_error_handler do
          desc 'Subscribe to expiration'
          task :subscribe do
            run %(cd #{current_path} && RAILS_ENV=#{rails_env} nohup rake global_error_handler:cleanup_database_dependencies >/dev/null 2>&1 & sleep 2)
            run %(cd #{current_path} && RAILS_ENV=#{rails_env} nohup rake global_error_handler:subscribe_to_expired >/dev/null 2>&1 & sleep 3)
          end

          desc 'Unsubscribe from expiration'
          task :unsubscribe do
            run %(cd #{current_path} && RAILS_ENV=#{rails_env} #{rake} global_error_handler:unsubscribe_from_expired)
          end

          desc 'Update Subscription to expiration'
          task :update_subscription do
            unsubscribe
            subscribe
          end

          namespace :initd do
            desc 'Generate geh_subscription init.d script'
            task :setup, roles: :app do
              run "mkdir -p #{shared_path}/config"
              location = File.expand_path('../../../config/templates/geh_subscription_init.sh.erb', __FILE__)
              config = ERB.new(File.read(location))
              put config.result(binding), "#{shared_path}/config/#{application}_geh_subscription_init.sh"
            end

            desc 'Copy geh_subscription into an init.d and adds to chkconfig'
            task :install, roles: :app do
              sudo "cp #{shared_path}/config/#{application}_geh_subscription_init.sh /etc/init.d/#{application}_geh_subscription;\
                sudo chmod +x /etc/init.d/#{application}_geh_subscription;\
                sudo chkconfig --add #{application}_geh_subscription", pty: true
            end

            desc 'Removes geh_subscription from an init.d and deletes from chkconfig'
            task :uninstall, roles: :app do
              sudo "chkconfig --del #{application}_geh_subscription;\
                sudo rm -f /etc/init.d/#{application}_geh_subscription", pty: true
            end
          end
        end
      end
    end
  end
end
