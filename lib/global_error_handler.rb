$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))

module GlobalErrorHandler
end

require 'resque'
require 'resque/server'
require 'haml'


require 'global_error_handler/redis'
require 'global_error_handler/parser'
require 'global_error_handler/handler'
require 'global_error_handler/app_exception'
require 'global_error_handler/server'

require 'global_error_handler/middleware'
require 'global_error_handler/rails' if defined? Rails::Railtie

require "global_error_handler/version"

Resque::Server.register GlobalErrorHandler::Server
