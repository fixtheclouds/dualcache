require 'dual_cache/file_storage'
require 'dual_cache/memory_storage'
require 'dual_cache/redis_storage'

module DualCache
  # Main storage class
  class Storage
    STRATEGIES = %w(least_used most_used).freeze
    STORAGES = {
      file: FileStorage,
      redis: RedisStorage
    }

    attr_reader :level1, :level2

    # Initialization
    #
    # Options keys:
    # strategy (string) caching strategy ('most_used'|'least_used')
    # l2_type (string) storage type
    # l1_size (integer) max cache size for MemoryStorage
    # l2_size (integer) max cache size for FileStorage
    def initialize(options = {})
      strategy = STRATEGIES.include?(options[:strategy]) ? options[:strategy] : 'least_used'
      @level1 = MemoryStorage.new(options[:l1_size], strategy)
      level2_storage_class = options[:l2_type]&.to_sym || :file
      raise StandardError, 'Invalid storage type' unless STORAGES.include?(level2_storage_class)

      @level2 = STORAGES[level2_storage_class].new(options[:l2_size], strategy)
      @mutex = Mutex.new
    end

    def clear(options = {})
      synchronize do
        level1.clear(options)
        level2.clear(options)
      end
    end

    def read(key, options = nil)
      synchronize do
        record = level1.read(key, options)
        if record.nil?
          record = level2.read(key, options)
          level1.write(key, record, {})
        end

        record
      end
    end

    def write(key, value, options = nil)
      synchronize do
        level2.delete(key, options)
        level1.write(key, value, options)
        prune_entries if level1.needs_prune?
      end
    end

    def delete(key, options = nil)
      synchronize do
        level1.delete(key, options)
        level2.delete(key, options)
      end
    end

    def synchronize(&block)
      @mutex.synchronize(&block)
    end

    private

    def prune_entries
      level1.keys.each do |key|
        move(key)

        return unless level1.needs_prune?
      end
    end

    def move(key)
      record = level1.read(key)
      level2.write(key, record)
      level1.delete(key)
    end
  end
end
