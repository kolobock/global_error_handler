module GlobalErrorHandler
  class Middleware #:nodoc:
    def initialize(app)
      @app = app
    end

    def call(env)
      exception = nil
      status, headers, response = @app.call(env)
    rescue StandardError => exception
      GlobalErrorHandler::Handler.new(env, exception).process_exception!
    ensure
      fail exception if exception
      [status, headers, response]
    end
  end
end
