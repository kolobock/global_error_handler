# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'global_error_handler/version'

Gem::Specification.new do |spec|
  spec.name          = 'global_error_handler'
  spec.version       = GlobalErrorHandler::VERSION
  spec.authors       = ['Andrii Rudenko']
  spec.email         = ['kolobock@gmail.com']
  spec.summary       = "Records application' exceptions into the separated redis database."
  spec.description   = 'On the middleware level catch an exception from Rails app and store in the separated Redis database.'
  spec.homepage      = 'https://github.com/kolobock/global_error_handler/'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3', '>= 10.3.2'
  spec.add_development_dependency 'capistrano', '< 3.0'

  spec.add_dependency 'resque', '~> 1.25', '>= 1.25.1'
  spec.add_dependency 'haml', '~> 4.0', '>= 4.0.5', '< 4.1'
  spec.add_runtime_dependency 'actionview', '>= 4.0.5', '< 4.3'
  spec.add_dependency 'hashie', '>= 3.3'
end
