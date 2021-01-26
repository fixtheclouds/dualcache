module DualCache
  module Mixins
    module LevelTwo
      def init_instance_variables(size, strategy)
        @max_size = size || 32.megabytes
        @pruning = false
        @strategy = strategy
        @mutex = Mutex.new
        @key_access = {}
      end
    end
  end
end
