require 'active_support/cache'

module DualCache
  # Level two cache
  # Adds `prune` functionality similar to MemoryStore
  # for removing files when cache size limit is exceeded
  class FileStorage < ActiveSupport::Cache::FileStore
    def initialize(cache_path, size)
      super(cache_path || 'tmp/cache')
      @max_size = size || 32.megabytes
      @pruning = false
    end

    # Mimics behaviour of ActiveSupport::Cache::MemoryStore#prune
    def prune(target_size)
      return if pruning?

      current_cache_size = cache_size
      @pruning = true
      begin
        cleanup
        search_dir(cache_path) do |fname|
          current_cache_size -= cached_size(fname, read_entry(fname, {}))
          delete_entry(fname, {})
          return if current_cache_size <= target_size
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

    def cache_size
      size = 0
      search_dir(cache_path) do |fname|
        entry = read_entry(fname, {})
        size += cached_size(fname, entry)
      end
      size
    end

    # Copy implementation but add cache size handling
    def write_entry(key, entry, options)
      return false if options[:unless_exist] && File.exist?(key)

      ensure_cache_path(File.dirname(key))
      File.atomic_write(key, cache_path) { |f| Marshal.dump(entry, f) }
      prune(@max_size * 0.75) if cache_size > @max_size
      true
    end
  end
end
