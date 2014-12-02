class GlobalErrorHandler::AppException
  class << self
    def all(page, field = nil, filter = nil)
      page ||= 0
      if field && filter
        keys = GlobalErrorHandler::Redis.filter_exception_keys page, "error_#{field}", filter
      else
        keys = GlobalErrorHandler::Redis.exception_keys page
      end
      GlobalErrorHandler::Redis.find_all keys
    end

    def count(field = nil, filter = nil)
      if field && filter
        GlobalErrorHandler::Redis.filtered_exceptions_count("error_#{field}", filter)
      else
        GlobalErrorHandler::Redis.exceptions_count
      end
    end

    def find(id)
      return if id.blank?
      GlobalErrorHandler::Redis.find exception_key(id)
    end

    def delete(id)
      return if id.blank?
      GlobalErrorHandler::Redis.delete exception_key(id)
    end

    def delete_all(ids)
      return if ids.blank?
      keys = ids.map{ |id| exception_key id }
      GlobalErrorHandler::Redis.delete_all keys
    end

    def truncate(filter = nil, opts = {})
      if filter
        field = opts.delete(:field)
        total = opts.delete(:total) || 1000
        size = 1000
        (total / size.to_f).ceil.times do |iteration|
          ids = filtered_ids_by field, filter, size, iteration
          delete_all ids unless ids.blank?
        end
      else
        GlobalErrorHandler::Redis.truncate!
      end
    end

    def filters_for(field)
      keys = GlobalErrorHandler::Redis.filter_keys_for "error_#{field}"
      return [] if keys.blank?
      keys.map do |key|
        key =~ /^#{GlobalErrorHandler::Redis::FILTER_KEY_PREFIX}:error_#{field}:(.*)/
        $1
      end
    end

    def filtered_ids_by(field, str, len=1000, page=0)
      keys = GlobalErrorHandler::Redis.filter_exception_keys page, "error_#{field}", str, len
      return [] if keys.blank?
      keys.map{ |key| key.split(':').last rescue nil }.compact
    end

    private

    def exception_key(id)
      GlobalErrorHandler::Redis.exception_key(id)
    end
  end
end
