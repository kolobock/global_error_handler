module GlobalErrorHandler
  class Railtie < Rails::Railtie #:nodoc:
    railtie_name :global_error_handler

    initializer 'global_error_handler.configure_rails_initialization' do
      insert_middleware
    end

    rake_tasks do
      load File.join(File.dirname(__FILE__), '..', 'tasks', 'global_error_handler.rake')
    end

    def insert_middleware
      if defined? ActionDispatch::DebugExceptions
        Rails.application.middleware.insert_after ActionDispatch::DebugExceptions, GlobalErrorHandler::Middleware
      else
        Rails.application.middleware.use GlobalErrorHandler::Middleware
      end
    end
  end
end
