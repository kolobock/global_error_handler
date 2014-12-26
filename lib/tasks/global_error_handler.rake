namespace :global_error_handler do
  desc 'Subscribe to expired keyevent notifications'
  task :subscribe_to_expired do
    GlobalErrorHandler::RedisNotificationSubscriber.subscribe!
  end
end
