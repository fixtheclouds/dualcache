require 'active_support/cache'
require 'dual_cache/mixins/level_two'

module DualCache
  class RedisStorage < ActiveSupport::Cache::RedisCacheStore
    include DualCache::Mixins::LevelTwo

    attr_reader :strategy

    def initialize(size, strategy = 'least_used')
      super
      init_instance_variables(size, strategy)
    end
  end
end
