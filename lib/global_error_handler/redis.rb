class GlobalErrorHandler::Redis
  CURRENT_ID_KEY       = 'global_error_handler:current_id'
  EXCEPTIONS_REDIS_KEY = 'global_error_handler:exceptions'
  EXCEPTION_KEY_PREFIX = 'global_error_handler:exception'
  FILTER_KEY_PREFIX    = 'global_error_handler:filter'
  FILTER_MAX_CHARS     = 60

  class << self
    def store(info_hash)
      redis_key = exception_key(next_id!)
      redis.hmset redis_key, info_hash.merge(id: current_id).to_a.flatten
      redis.rpush EXCEPTIONS_REDIS_KEY, redis_key
      %w(error_class error_message).each do |field|
        redis.rpush filter_key(field, build_filter_value(info_hash[field.to_sym])), redis_key
      end
    end

    def redis
      @redis ||= begin
                   unless $redis_global_exception_handler.is_a? Redis
                     redis_config = YAML.load_file(File.join(Rails.root, 'config', 'redis.yml'))[Rails.env]
                     $redis_global_exception_handler = Redis.new(redis_config['global_exception_handler'])
                   end
                   $redis_global_exception_handler
                 end
    end

    def current_id
      redis.get(CURRENT_ID_KEY)
    end

    # def sort(field, direction = 'ASC', page = 0, per_page = 1000)
    #   redis.sort(EXCEPTIONS_REDIS_KEY, by: "#{EXCEPTION_KEY_PREFIX}_*->#{field}_*", order: "#{direction}", limit: [page, per_page])
    # end

    def exceptions_count
      redis.llen EXCEPTIONS_REDIS_KEY
    end

    def filtered_exceptions_count(field, filter)
      redis.llen filter_key(field, filter)
    end

    def exception_keys(start = 0, per_page = 10)
      redis.lrange EXCEPTIONS_REDIS_KEY, start.to_i, per_page.to_i + start.to_i - 1
    end

    def filter_exception_keys(start = 0, field = nil, filter = nil, per_page = 10)
      redis.lrange filter_key(field, filter), start.to_i, per_page.to_i + start.to_i - 1
    end

    def filter_keys_for(field, filter = '')
      redis.keys filter_key(field, "#{filter}*")
    end

    def find(key)
      Hashie::Mash.new redis.hgetall(key)
    end

    def find_all(keys)
      keys.map { |key| find(key) }
    end

    def delete(key)
      redis.lrem EXCEPTIONS_REDIS_KEY, 1, key
      clear_filters key
      redis.del key
    end

    def delete_all(keys)
      keys.each { |key| delete(key) rescue next }
    end

    def truncate!
      redis.flushdb
    end

    def exception_key(id = current_id)
      "#{EXCEPTION_KEY_PREFIX}:#{id}"
    end

    def filter_key(field, filter)
      "#{FILTER_KEY_PREFIX}:#{field}:#{filter}"
    end

    protected

    def next_id!
      redis.incr(CURRENT_ID_KEY)
    end

    def clear_filters(key)
      %w(error_class error_message).each do |field|
        field_value = build_filter_value(find(key)[field.to_sym])
        filter_keys_for(field, field_value).each do |filter_key|
          redis.lrem filter_key, 1, key
        end
      end
    end

    private

    def build_filter_value(txt)
      str = txt.split("\n").first rescue ''
      str[0...FILTER_MAX_CHARS]
    end
  end
end
