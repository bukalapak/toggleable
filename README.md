# toggleable
[![CircleCI](https://circleci.com/gh/bukalapak/toggleable.svg?style=svg)](https://circleci.com/gh/bukalapak/toggleable)
[![codecov](https://codecov.io/gh/bukalapak/toggleable/branch/master/graph/badge.svg)](https://codecov.io/gh/bukalapak/toggleable)

Gem for toggling tools.

## Getting started

Install with:

```
$ gem install toggleable
```

You should initialize the toggleable first:

```ruby
require "toggleable"

Toggleable.configure do |t|
  t.expiration_time = 3.minutes
end
```

You can pass the configurations for toggleable in the block above. Here is the configurable list:

* use_memoization : set `true` to use memoization, so it doesn't hit your storage often. Default: `false`
* expiration_time : Duration for memoization expiry. Default: `5 minutes`
* storage : Storage persistence to use, you should pass an object that responds to methods that specified in `Toggleable::StorageAbstract` class or use the provided implementation in `toggleable/storage/*.rb`. If not provided, it will use memory store as persistence. Default: `Toggleable::MemoryStore`
* namespace : Prefix namespace for your stored keys. Default: `toggleable`
* logger : Logger to use, you should pass an object that respond to methods that speciied in `Toggleable::LoggerAbstract` class. It will not log if none provided. Default: `none`

### Usage

You could include `Toggleable::Base` to a class to provide toggling ability for that class.

```ruby
class SampleFeature
  include Toggleable::Base

  DESC = 'this class can now be toggled'.freeze
end

SampleFeature.active?
# => 'false'

SampleFeature.activate!
# => "true"

# supply an actor for logging purposes
SampleFeature.deactivate! actor: user.id
# => 'false'
```

### Managing Toggles

You could manage your toggles using `Toggleable::FeatureToggler` class.

```
# This will get all keys and its value
Toggleable::FeatureToggler.instance.available_features
# => {'key': 'true', 'other_key': 'false'}

Toggleable::FeatureToggler.mass_toggle!(mapping, actor: user.id)
# => 'true'
```

### Redis Store Implementation

Redis implementation is also provided, you only need to pass your redis instance when configuring.

```ruby
require 'redis'

redis = Redis.new

Toggleable.configure do |t|
  t.storage = Toggleable::RedisStore.new(redis)
end
```

## Testing

This gem is tested against recent Ruby and ActiveSupport versions.


## Contributor

[BUKALAPAK TEAM](https://github.com/bukalapak/toggleable/graphs/contributors)

## Contributing

Fork the project and send pull requests.
