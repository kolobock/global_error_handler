require 'global_error_handler/redis'

class GlobalErrorHandler::RedisNotificationSubscriber
  def self.subscribe_to_expiration
    redis.unsubscribe sub_channel rescue nil
    redis.subscribe(sub_channel) do |on|
      puts "*** Listeting for the notifications on ##{sub_channel}..."
      on.message do |channel, key|
        puts "**** ##{channel}: #{key}"
        redis.unsubscribe if key == "exit"

        if key =~ /#{GlobalErrorHandler::Redis.exception_key("\\d+")}/
          GlobalErrorHandler::Redis.delete_dependencies key
        end
      end
    end
  end

  def self.redis
    GlobalErrorHandler::Redis.redis
  end

  def self.sub_channel
    "__keyevent@#{redis.client.db}__:expired"
  end
end
