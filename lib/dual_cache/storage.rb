require 'dual_cache/file_storage'
require 'dual_cache/memory_storage'

module DualCache
  # Main storage class
  class Storage
    attr_reader :level1, :level2

    # Initialization
    #
    # Options keys:
    # path (string) cache_path for FileStorage
    # l1_size (integer) max cache size for MemoryStorage
    # l2_size (integer) max cache size for FileStorage
    def initialize(options = {})
      @level1 = MemoryStorage.new(options[:l1_size])
      @level2 = FileStorage.new(options[:cache_path], options[:l2_size])
    end

    def clear(options = nil)
      level1.clear(options)
      level2.clear(options)
    end

    def read(key, options = nil)
      record = level1.read(key, options)
      if record.nil?
        record = level2.read(key, options)
        level1.write(key, record, {})
      end

      record
    end

    def write(key, value, options = nil)
      level2.delete(key, options)
      level1.write(key, value, options)
      prune_entries if level1.needs_prune?
    end

    def delete(key, options = nil)
      level1.delete(key, options)
      level2.delete(key, options)
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
