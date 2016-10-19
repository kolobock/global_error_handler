namespace :global_error_handler do
  desc 'Subscribe to expired keyevent notifications'
  task subscribe_to_expired: :environment do
    if pid_file_exists?
      begin
        Process.kill 0, process_id
        puts '*** already running!'
        next
      rescue Errno::ESRCH
      end
    end

    File.open(pid_file, 'w') { |f| f.puts Process.pid }

    begin
      GlobalErrorHandler::RedisNotificationSubscriber.subscribe!
    ensure
      File.unlink(pid_file) rescue nil
    end
  end

  desc 'Unsubscribe from expired keyevent notifications'
  task unsubscribe_from_expired: :environment do
    puts('*** pid file does not exist!') || next unless pid_file_exists?

    begin
      Process.kill 0, process_id
      GlobalErrorHandler::RedisNotificationSubscriber.unsubscribe!

      term_signals = [2, 3, 15, 9].to_enum
      begin
        puts "** Sending signal #{term_signals.peek} to ##{process_id}..."
        Process.kill(term_signals.next, process_id)

        i_try = 0
        while i_try <= 3
          Process.kill 0, process_id
          i_try += 1
          sleep 1
          raise RetryIteration if i_try == 3
        end
      rescue RetryIteration
        retry
      rescue StopIteration
        puts '*** failed to stop a process!'
      rescue Errno::ESRCH, Errno::ENOENT
        puts '*** successfully stopped!'
      end
    rescue Errno::ESRCH
      puts "** No such process ##{process_id}. Exiting..."
    ensure
      File.unlink(pid_file) rescue nil
    end
  end

  desc 'Clean database dependencies for exception keys'
  task cleanup_database_dependencies: :environment do
    puts '** starting CleanUp process...'
    GlobalErrorHandler::Redis.cleanup_database_dependencies!
    puts '** completed CleanUp process.'
  end

  class RetryIteration < StandardError; end

  def pid_location
    pid_dir = [
      File.join(Rails.root, '..', 'shared', 'pids'),
      File.join(Rails.root, '..', '..', 'shared', 'pids'),
      File.join(Rails.root, 'tmp', 'pids')
    ].detect { |dir_name| Dir.exist?(dir_name) }

   File.expand_path pid_dir
  end

  def pid_file
    @pid_file ||= File.join(pid_location, 'global_error_handler_subscription.pid')
  end

  def process_id
    File.read(pid_file).to_i
  end

  def pid_file_exists?
    File.exist? pid_file
  end
end
