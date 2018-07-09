module PgConduit
  # Wraps an enumerable so that it can be used in place of a
  # PgConduit::QueryStream
  class EnumStream
    # @param enum [Enumerable] An enumerable object
    def initialize(enum)
      @enum = enum
    end

    # @param filter [Proc,Object] Proc or Object that responds to 'call()'
    # @return [self]
    def select(filter)
      self.tap { @filter = filter }
    end

    # Execute query and yield each row
    # @yield [Hash] A hash representing a single row from the result set
    def each(&b)
      @enum.select(&@filter).each(&b)
    end
  end
end
