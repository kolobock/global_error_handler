# GlobalErrorHandler

GlobalErrorHandler catches application exceptions on the middleware level and store them into the redis database.
It adds Exceptions tab to Redis Web server in case to view, filter, delete or truncate them.

- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Exceptions tab](#exceptions-tab)
  - [Truncate / Delete](#truncatedelete-functionality)
  - [RescueFrom](#rescue_from)
- [Data structure](#data-structure)
- [Contributing](#contributing)

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

### Exceptions tab
#### Index page
Target your browser to `/resque/exceptions/` path of your Rails Application server to view all Exceptions.
#### Filters
There are two types of filtering: by Error Class and Error Message.
Select any `Error Class Filter` or `Error Message Filter` from drop-down to view filtered exceptions.
#### Show
Click on `Timestamp` or `Error Class` hyperlink to view details of the exception.

### Truncate/Delete functionality
#### Truncate
*Truncate all* deletes all Exceptions by filter if filter is selected or _ALL_ Exceptions otherwise.
#### Delete
* *Delete* deletes exception from the database.
* *Delete selected* deletes the selected exceptions from the database. Clicking on the table caption checkbox selects/deselects the list.

### rescue_from
If `rescue_from` is used in your application, add following line at top of the method specified to `with:` parameter of resque_from helper.

```ruby
GlobalErrorHandler::Handler.new(request.env, exception).process_exception!
```

### Subscribe to expired key notifications
Following command should run on your server in case to automatically clear filters on deleting keys from redis due to expiration.
Default expiration time is set to 4 weeks (`GlobalErrorHandler::Redis::REDIS_TTL`)

```ruby
rake global_error_handler:subscribe_to_expired
```

In case to stop subscription, run following below command

```ruby
rake global_error_handler:unsubscribe_from_expired
```

## Data structure
Redis database data structure contains following below keys:
- 'global_error_handler:current_id' : *STRING* - stores current id of an exception. It is being incremented on adding new exception into database
- 'global_error_handler:exceptions' : *LIST* - stores all the exception' keys.
- 'global_error_handler:exception:\<id\>' : *HASH* - exception key, where \<id\>: number from current_id + 1. Exception key consists of the following attributes:
  - id - exception's internal id
  - error_class - `error.class`
  - error_message - `error.message`
  - error_trace - `error.backtrace`
  - user_agent - `request.user_agent`
  - request_method - `request.method`
  - request_params - `request.params`
  - target_url - `request.url`
  - referer_url - `request.referer`
  - user_info - IP Address information
  - timestamp - time when exception was raised
- 'global_error_handler:filter:\<field\>:\<filter\>' : *LIST* - stores exception' keys that are filtered by field and filter. where \<field\>: either `error_class` or `error_message`, \<filter\>: string stored in the appropriated attribute.

## Contributing

1. Fork it ( https://github.com/kolobock/global_error_handler/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
