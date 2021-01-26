require 'active_support/cache'
require 'dual_cache/mixins/level_two'

module DualCache
  class FileStorage < ActiveSupport::Cache::FileStore
    include DualCache::Mixins::LevelTwo

    attr_reader :strategy

    def initialize(size, strategy = 'least_used')
      super('tmp/cache')
      init_instance_variables(size, strategy)
    end

    def clear(options = {})
      synchronize { @key_access.clear }
      super
    end

    # Mimics behaviour of ActiveSupport::Cache::MemoryStore#prune
    def prune(target_size)
      return if pruning?

      current_cache_size = cache_size
      @pruning = true
      begin
        cleanup
        keys.each do |fname|
          current_cache_size -= cached_size(fname, read_entry(fname, {}, true))
          delete_entry(fname, {})
          return if current_cache_size <= target_size
        end
      ensure
        @pruning = false
      end
    end

    def keys
      synchronize do
        @key_access.keys.sort do |a, b|
          if strategy == 'least_used'
            @key_access[a].to_f <=> @key_access[b].to_f
          else
            @key_access[b].to_f <=> @key_access[a].to_f
          end
        end
      end
    end

    def synchronize(&block)
      @mutex.synchronize(&block)
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
        entry = read_entry(fname, {}, true)
        size += cached_size(fname, entry)
      end
      size
    end

    def read_entry(key, options, skip_access = false)
      if File.exist?(key)
        @key_access[key] = Time.now.to_f unless skip_access
        File.open(key) { |f| Marshal.load(f) }
      else
        @key_access.delete(key) unless skip_access
        false
      end
    rescue => e
      logger.error("FileStoreError (#{e}): #{e.message}") if logger
      nil
    end

    def write_entry(key, entry, options)
      ensure_cache_path(File.dirname(key))
      File.atomic_write(key, cache_path) { |f| Marshal.dump(entry, f) }
      @key_access[key] = Time.now.to_f
      prune(@max_size * 0.75) if cache_size > @max_size
      true
    end

    def delete_entry(key, options)
      if File.exist?(key)
        begin
          File.delete(key)
          delete_empty_directories(File.dirname(key))
          @key_access.delete(key)
          true
        rescue => e
          raise e if File.exist?(key)
          false
        end
      end
    end
  end
end
