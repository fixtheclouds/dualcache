require 'active_support/cache'
require 'dual_cache/file_storage'

module DualCache
  # Main storage class
  # Implements level one (in-memory) cache
  class Storage < ActiveSupport::Cache::MemoryStore
    attr_reader :level2

    # Initialization
    #
    # Options keys:
    # path (string) cache_path for FileStorage
    # l1_size (integer) max cache size for MemoryStorage
    # l2_size (integer) max cache size for FileStorage
    def initialize(options = {})
      super(size: options[:l1_size])
      @level2 = FileStorage.new(options[:cache_path], options[:l2_size])
    end

    def clear(options = nil)
      super
      level2.clear(options)
    end

    def read(key, options = nil)
      record = super

      if record.nil?
        record = level2.read(key, options)
        write(key, record, {})
      end

      record
    end

    def write(key, value, options = nil)
      level2.delete(key, options)

      super
    end

    def delete(key, options = nil)
      super || level2.delete(key, options)
    end

    # Copy prune implementation but allow delegation to second level
    def prune(target_size, max_time = nil)
      return if pruning?

      @pruning = true
      begin
        start_time = Time.now
        cleanup
        instrument(:prune, target_size, from: @cache_size) do
          keys = synchronize { @key_access.keys.sort { |a, b| @key_access[a].to_f <=> @key_access[b].to_f } }
          keys.each do |key|
            move(key)
            return if @cache_size <= target_size || (max_time && Time.now - start_time > max_time)
          end
        end
      ensure
        @pruning = false
      end
    end

    private

    def move(key)
      record = read(key)
      level2.write(key, record)
      delete(key)
    end
  end
end
