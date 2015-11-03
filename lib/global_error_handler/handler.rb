module GlobalErrorHandler
  class Handler #:nodoc:
    def initialize(env, exception)
      @env = env
      @exception = exception
      @controller = @env['action_controller.instance']
      @parsed_error = nil
    end

    def process_exception!
      return if @env['global_error_handler.proceed_time']
      @env['global_error_handler.proceed_time'] = Time.current.utc
      parse_exception
      store_exception
    end

    private

    def parse_exception
      @parsed_error = Parser.new(@env, @exception, @controller).parse
    end

    def store_exception
      Redis.store(@parsed_error.info_hash)
    end
  end
end
