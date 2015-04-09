$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../../lib'))

require 'capistrano'
if Capistrano::Configuration.instance
  require 'recipes/global_error_handler'
  GlobalErrorHandler::Capistrano.load_into Capistrano::Configuration.instance
end
