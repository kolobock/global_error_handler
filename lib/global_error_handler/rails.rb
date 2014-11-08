class GlobalErrorHandler::Railtie < Rails::Railtie
  initializer 'global_error_handler.configure_rails_initialization' do
    insert_middleware
  end

  def insert_middleware
    if defined? ActionDispatch::DebugExceptions
      Rails.application.middleware.insert_after ActionDispatch::DebugExceptions, GlobalErrorHandler::Middleware
    else
      Rails.application.middleware.use GlobalErrorHandler::Middleware
    end
  end
end
