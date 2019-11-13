# DualCache

Configurable two-level caching system

## Usage

```ruby
require 'dual_cache'

cache = DualCache::Storage.new(
  cache_path: 'tmp', 
  l1_size: 1.megabyte, 
  l2_size: 256.megabytes
)

cache.write('foo', 'bar') # => true
cache.read('foo') # => 'bar'
cache.delete('foo') # => true
cache.clear # => true
```

### Initialization params hash keys

- `cache_path`: relative path to file storage files
- `l1_size`: maximum cache size in bytes for l1
- `l2_size`: maximum cache size in bytes for l2

## Testing

```
$ bundle exec rspec
```
