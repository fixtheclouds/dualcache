# DualCache

Configurable two-level caching system

## How it works
- Items are written to level 1 cache first
- Items that exceed level 1 size limit are moved to level 2
- Items from level 2 are restored to level 1 when accessed
- Items that exceed level 2 size are removed from cache
  based on strategy provided

## Usage

```ruby
require 'dual_cache'

cache = DualCache::Storage.new(
  strategy: 'most_used',
  l1_size: 1.megabyte,
  l2_size: 256.megabytes
)

cache.write('foo', 'bar') # => true
cache.read('foo') # => 'bar'
cache.delete('foo') # => true
cache.clear # => true
```

### Initialization params hash keys

- `strategy`: caching strategy (`least_used`|`most_used`)
- `l1_size`: maximum cache size in bytes for l1
- `l2_size`: maximum cache size in bytes for l2

## Testing

```
$ bundle exec rspec
```

## TODO

- Implement more caching strategies
- Implement various cache storages (e.d. redis, memcached)
- Connect CI, add coverage
