module GlobalErrorHandler
  class AppException #:nodoc:
    class << self
      def all(start, field = nil, filter = nil)
        start ||= 0
        if field && filter
          keys = Redis.filter_exception_keys start, "error_#{field}", filter
        else
          keys = Redis.exception_keys start
        end
        Redis.find_all keys
      end

      def count(field = nil, filter = nil)
        if field && filter
          Redis.filtered_exceptions_count("error_#{field}", filter)
        else
          Redis.exceptions_count
        end
      end

      def find(id)
        return if id.blank?
        Redis.find exception_key(id)
      end

      def delete(id)
        return if id.blank?
        Redis.delete exception_key(id)
      end

      def delete_all(ids)
        return if ids.blank?
        keys = ids.map { |id| exception_key id }
        Redis.delete_all keys
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
          Redis.truncate!
        end
      end

      def filters_for(field)
        keys = Redis.filter_keys_for "error_#{field}"
        return [] if keys.blank?
        keys.map do |key|
          key =~ /^#{Redis::FILTER_KEY_PREFIX}:error_#{field}:(.*)/
          Regexp.last_match(1)
        end
      end

      def filtered_ids_by(field, str, len = 1000, start = 0)
        keys = Redis.filter_exception_keys start, "error_#{field}", str, len
        return [] if keys.blank?
        keys.map do |key|
          begin
            key.split(':').last
          rescue
            nil
          end
        end.compact
      end

      private

      def exception_key(id)
        Redis.exception_key(id)
      end
    end # class << self
  end
end
