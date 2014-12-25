require 'global_error_handler/redis'

class GlobalErrorHandler::RedisNotificationSubscriber
  def self.subscribe_to_expiration
    check_redis_config
    begin
      redis.unsubscribe sub_channel rescue nil
      redis.subscribe(sub_channel) do |on|
        puts "*** ##{Process.pid}: Listeting for the notifications on ##{sub_channel}..."
        on.message do |channel, key|
          puts "**** ##{channel}: #{key}"
          GlobalErrorHandler::Redis.delete_dependencies(key) if key =~ /#{GlobalErrorHandler::Redis.exception_key("\\d+")}/
        end

        on.subscribe do |channel, subscriptions|
          puts "##{Process.pid}: Subscribed to ##{channel} (#{subscriptions} subscriptions)"
        end

        on.unsubscribe do |channel, subscriptions|
          puts "##{Process.pid}: Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
        end
      end
    rescue Redis::BaseConnectionError => error
      puts "##{Process.pid}: #{error}, retrying in 1s"
      sleep 1
      retry
    end
  end

  def self.redis
    GlobalErrorHandler::Redis.redis
  end

  def self.sub_channel
    @sub_channel ||= "__keyevent@#{self.redis.client.db}__:expired"
  end

  def self.check_redis_config
    # x     Expired events (events generated every time a key expires)
    # g     Generic commands (non-type specific) like DEL, EXPIRE, RENAME, ...
    # A     Alias for g$lshzxe, so that the "AKE" string means all the events.
    # E     Keyevent events, published with __keyevent@<db>__ prefix.
    ### AE|gE|xE|AKE|gKE|xKE
    redis.config 'set', 'notify-keyspace-events', 'xE' unless redis.config('get', 'notify-keyspace-events').last =~ /[Agx]+.?E+/
  end
end
