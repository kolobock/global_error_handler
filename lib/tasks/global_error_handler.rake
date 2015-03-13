namespace :global_error_handler do
  desc 'Subscribe to expired keyevent notifications'
  task subscribe_to_expired: :environment do
    puts '*** pid file exists!' or next if File.exists?(pid_file)
    File.open(pid_file, 'w'){|f| f.puts Process.pid}
    begin
      GlobalErrorHandler::RedisNotificationSubscriber.subscribe!
    ensure
      File.unlink pid_file rescue nil
    end
  end

  desc 'Unsubscribe from expired keyevent notifications'
  task unsubscribe_from_expired: :environment do
    puts '*** pid file does not exist!' or next unless File.exists?(pid_file)
    process_id = File.read(pid_file).to_i
    begin
      Process.kill 0, process_id
      GlobalErrorHandler::RedisNotificationSubscriber.unsubscribe!
      puts "** Terminating ##{process_id}..."
      Timeout.timeout(10) { Process.kill 15, process_id }
    rescue Timeout::Error
      puts "** Killing ##{process_id} after waiting for 10 seconds..."
      Process.kill 9, process_id
    rescue Errno::ESRCH
      puts "** No such process ##{process_id}. Exiting..."
    ensure
      File.unlink pid_file rescue nil
    end
  end

  desc 'Clean database dependencies for exception keys'
  task cleanup_database_dependencies: :environment do
    puts '** starting CleanUp process...'
    GlobalErrorHandler::Redis.cleanup_database_dependencies!
    puts '** completed CleanUp process.'
  end

  def pid_file
    @pid_file ||= File.expand_path('./tmp/pids/global_error_handler_subscription.pid')
  end
end
