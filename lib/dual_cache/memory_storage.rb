require 'active_support/cache'

module DualCache
  # Level one cache
  class MemoryStorage < ActiveSupport::Cache::MemoryStore
    def initialize(size)
      super(size: size)
    end

    # Remove #prune call from implementation
    def write_entry(key, entry, options)
      entry.dup_value!
      synchronize do
        old_entry = @data[key]
        return false if @data.key?(key) && options[:unless_exist]

        if old_entry
          @cache_size -= (old_entry.size - entry.size)
        else
          @cache_size += cached_size(key, entry)
        end
        @key_access[key] = Time.now.to_f
        @data[key] = entry
        true
      end
    end

    def needs_prune?
      synchronize { @cache_size > @max_size * 0.75 }
    end

    def keys
      synchronize { @key_access.keys.sort { |a, b| @key_access[a].to_f <=> @key_access[b].to_f } }
    end
  end
end
