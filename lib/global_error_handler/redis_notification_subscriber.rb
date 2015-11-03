require 'global_error_handler/redis'

module GlobalErrorHandler
  class RedisNotificationSubscriber #:nodoc:
    class << self
      def unsubscribe!
        redis.unsubscribe(sub_channel)
      rescue
        nil
      end

      def subscribe!
        check_redis_config
        begin
          fail SubscriptionError, "wont subscribe to ##{sub_channel}. Someone already listening to this channel" if subscribers_count > 0
          redis.subscribe(sub_channel) do |on|
            puts "*** ##{Process.pid}: Listeting for the notifications on ##{sub_channel}..."
            on.message do |channel, key|
              puts "**** ##{channel}: #{key}"
              Redis.delete_dependencies(key) if key =~ /#{Redis.exception_key("\\d+")}/
            end
            on.subscribe do |channel, subscriptions|
              puts "##{Process.pid}: Subscribed to ##{channel} (#{subscriptions} subscriptions)"
            end

            on.unsubscribe do |channel, subscriptions|
              puts "##{Process.pid}: Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
            end
          end
        rescue ::Redis::BaseConnectionError => error
          puts "##{Process.pid}: #{error}, retrying in 1s"
          sleep 1
          retry
        rescue SubscriptionError => error
          puts "##{Process.pid}: #{error}, retrying in 1s"
          sleep 1
          retry
        rescue Interrupt => error
          puts "##{Process.pid}: unsubscribing..."
          unsubscribe!
          redis.quit
          redis.client.reconnect
        end
      end

      def redis
        @redis ||= Redis.initialize_redis_from_config
      end

      def sub_channel
        @sub_channel ||= "__keyevent@#{redis.client.db}__:expired"
      end

      def check_redis_config
        # x     Expired events (events generated every time a key expires)
        # g     Generic commands (non-type specific) like DEL, EXPIRE, RENAME, ...
        # A     Alias for g$lshzxe, so that the "AKE" string means all the events.
        # E     Keyevent events, published with __keyevent@<db>__ prefix.
        ### AE|gE|xE|AKE|gKE|xKE
        redis.config('set', 'notify-keyspace-events', 'xE') unless redis.config('get', 'notify-keyspace-events').last =~ /[Agx]+.?E/
      end

      def subscribers_count
        redis.publish sub_channel, "check subscribers count from ##{Process.pid}"
      end
    end # class << self

    class SubscriptionError < StandardError; end
  end
end
