class GlobalErrorHandler::Parser
  attr_reader :info_hash

  def initialize(env, exception, controller)
    @env = env
    @exception = exception
    @controller = controller
    @request = ActionDispatch::Request.new(@env)
    @info_hash = {}
  end

  def parse
    @info_hash[:error_class]    = @exception.class.to_s.strip
    @info_hash[:error_message]  = @exception.message.to_s.strip
    @info_hash[:error_trace]    = @exception.backtrace.join("\n")
    @info_hash[:request_method] = @request.method
    @info_hash[:request_params] = @request.params
    @info_hash[:target_url]     = @request.url
    @info_hash[:referer_url]    = @request.referer
    @info_hash[:user_agent]     = @request.user_agent
    @info_hash[:user_info]      = user_info
    @info_hash[:timestamp]      = Time.now.utc
    self
  end

  private

  def user_info
    {
      Orig_IP_Address: get_remote_ip,
      IP_Address: @request.ip,
      Remote_Address: @request.remote_addr
    }
  end

  def get_remote_ip
    @request.remote_ip
  rescue => e
    e.message
  end
end
