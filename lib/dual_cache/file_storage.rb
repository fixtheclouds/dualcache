# Second level

require 'active_support/cache'

module DualCache
  class FileStorage < ActiveSupport::Cache::FileStore
    def initialize(cache_path, size)
      super(cache_path || 'tmp/cache')
      @max_size = size || 32.megabytes
      @cache_size = compute_size
      @pruning = false
    end

    def clear(options = nil)
      super
      @cache_size = 0
    end

    # Copies behaviour of ActiveSupport::Cache::MemoryStore#prune
    def prune(target_size, max_time = nil)
      return if pruning?

      @pruning = true
      begin
        cleanup
        search_dir(cache_path) do |fname|
          delete_entry(fname, {})

          return if @cache_size <= target_size
        end
      ensure
        @pruning = false
      end
    end

    private

    PER_ENTRY_OVERHEAD = 240

    def cached_size(key, entry)
      key.to_s.bytesize + entry.size + PER_ENTRY_OVERHEAD
    end

    def pruning?
      @pruning
    end

    def compute_size
      cache_size = 0
      search_dir(cache_path) do |fname|
        entry = read_entry(fname, {})
        cache_size += cached_size(fname, entry)
      end
      cache_size
    end

    # Copy implementation but add cache size handling
    def write_entry(key, entry, options)
      return false if options[:unless_exist] && File.exist?(key)

      ensure_cache_path(File.dirname(key))
      old_entry = File.exist?(key) && read_entry(key, options)
      File.atomic_write(key, cache_path) { |f| Marshal.dump(entry, f) }
      if old_entry
        @cache_size -= (old_entry.size - entry.size)
      else
        @cache_size += cached_size(key, entry)
      end
      prune(@max_size * 0.75) if @cache_size > @max_size
      true
    end

    # Copy implementation but add cache size handling
    def delete_entry(key, options)
      if File.exist?(key)
        begin
          old_entry = read_entry(key, options)
          File.delete(key)
          delete_empty_directories(File.dirname(key))
          @cache_size -= cached_size(key, old_entry)
          true
        rescue => e
          # Just in case the error was caused by another process deleting the file first.
          raise e if File.exist?(key)
          false
        end
      end
    end
  end
end
