class GlobalErrorHandler::Middleware
  def initialize(app)
    @app = app
  end

  def call(env)
    exception = nil
    status, headers, response = @app.call(env)
  rescue Exception => exception
    GlobalErrorHandler::Handler.new(env, exception).process_exception!
  ensure
    raise exception if exception
    [status, headers, response]
  end
end
