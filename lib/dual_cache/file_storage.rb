# Second level

require 'active_support/cache'

module DualCache
  class FileStorage < ActiveSupport::Cache::FileStore
    def initialize(cache_path, size)
      super(cache_path || 'tmp/cache')
    end
  end
end
