# GlobalErrorHandler

GlobalErrorHandler catches application exceptions on the middleware level and store them into the redis database.
It adds Exceptions tab to Redis Web server in case to view, filter, delete or truncate them.

## Installation

Add this line to your application's Gemfile:

    gem 'global_error_handler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install global_error_handler

## Configuration

Add redis database configuration into `global_exceptions_handler` section of _redis.yml_. See [redis_example.yml](https://github.com/kolobock/global_error_handler/blob/master/config/redis_example.yml) for more details.

## Usage

Target your browser to `/resque/exceptions/` path of your Rails Application server to view all Exceptions.
*Truncate all* deletes all Exceptions by filter if filter is selected or _ALL_ Exceptions otherwise.

If `rescue_from` is used in your application, add following line at top of the method specified to `with:` parameter of resque_from helper.

```ruby
GlobalErrorHandler::Handler.new(request.env, exception).process_exception!
```

## Contributing

1. Fork it ( https://github.com/kolobock/global_error_handler/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
