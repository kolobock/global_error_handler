class GlobalErrorHandler::Redis
  CURRENT_ID_KEY       = 'global_error_handler:current_id'
  EXCEPTIONS_REDIS_KEY = 'global_error_handler:exceptions'
  EXCEPTION_KEY_PREFIX = 'global_error_handler:exception'
  FILTER_KEY_PREFIX    = 'global_error_handler:filter'
  FILTER_FIELDS        = %w(error_class error_message)
  FILTER_MAX_CHARS     = 60
  REDIS_TTL            = 4 * 7 * 24 * 60 * 60 # 4 weeks

  class << self
    def store(info_hash)
      return if info_hash.blank?
      redis_key = exception_key(next_id!)
      redis.hmset redis_key, info_hash.merge(id: current_id).to_a.flatten
      redis.rpush EXCEPTIONS_REDIS_KEY, redis_key
      FILTER_FIELDS.each do |field|
        redis.rpush filter_key(field, build_filter_value(info_hash[field.to_sym])), redis_key
      end
      redis.expire redis_key, REDIS_TTL
    end

    def initialize_redis_from_config #:nodoc:
      redis_config = YAML.load_file(File.join(Rails.root, 'config', 'redis.yml'))[Rails.env]
      Redis.new(redis_config['global_exception_handler'])
    end

    def redis
      @redis ||= begin
                   $redis_global_exception_handler = initialize_redis_from_config unless $redis_global_exception_handler.is_a? Redis
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
      keys.map { |key| find(key) }.compact
    end

    def delete(key)
      delete_dependencies key
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

    def delete_dependencies(key)
      redis.lrem EXCEPTIONS_REDIS_KEY, 1, key
      clear_filters key
    end

    def clear_filters(key)
      FILTER_FIELDS.each do |field|
        retry_count = 0
        field_value = build_filter_value(redis.hget key, field)
        begin
          filter_keys_for(field, field_value).each do |filter_key|
            redis.lrem filter_key, 1, key
          end
        rescue
          field_value = ''
          retry if (retry_count += 1) < 2
        end
      end
    end

    def cleanup_database_dependencies!
      total_exceptions_count = exceptions_count
      total_exception_keys_count = redis.keys(exception_key('*')).size
      if total_exceptions_count > total_exception_keys_count
        puts "==> Database dependency is broken. Need to fix it!"
        start = 0
        per_page = 500
        exception_keys_to_be_cleaned_up = []
        valid_chunks_count = 0
        cleanup_count = exception_keys_to_be_cleaned_up.size
        while total_exceptions_count >= start + per_page
          exception_keys(start, per_page).each do |redis_key|
            exception_keys_to_be_cleaned_up.push redis_key unless redis.exists(redis_key)
          end
          if cleanup_count == (cleanup_count = exception_keys_to_be_cleaned_up.size)
            valid_chunks_count += 1
          end
          break if valid_chunks_count > 3 #if three ranges in a row are consistent, treat database consistency and finish looping
          start += per_page
        end

        puts "*** found #{exception_keys_to_be_cleaned_up.count} broken dependency keys."
        exception_keys_to_be_cleaned_up.each do |redis_key|
          delete_dependencies(redis_key) rescue next
        end
      else
        puts "==> Database dependency is OK. No need to fix it!"
      end
    end

    protected

    def next_id!
      redis.incr(CURRENT_ID_KEY)
    end

    private

    def build_filter_value(txt)
      str = txt.split("\n").first rescue ''
      str[0...FILTER_MAX_CHARS]
    end
  end
end
