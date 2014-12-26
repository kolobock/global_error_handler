desc 'Subscribe to expired keyevent notifications'
task :subscribe_to_expired do
  GlobalErrorHandler::RedisNotificationSubscriber.subscribe!
end
