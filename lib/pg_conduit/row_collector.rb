module PgConduit
  # Collects rows and yields them in chunks
  class RowCollector
    # @param chunk_size [Integer] How many rows should be collected before
    #   yielding
    def initialize(chunk_size: 100)
      @chunk_size = chunk_size
      @rows = []
      @finished = false
    end

    # @param chunk_size [Integer]
    # @return [self]
    def every(chunk_size, &callback)
      @chunk_size = chunk_size
      @callback = callback
      self
    end

    # @param row [Object] Row to add to the collected rows
    def <<(row)
      if @finished
        raise 'Data may not be added to a row collector that has been marked as finished'
      end

      Fiber.new do
        @rows << row
        if @rows.length % @chunk_size == 0
          flush(&@callback)
        end
        Fiber.yield
      end.resume
    end

    # Flushes any collected rows, yielding them to the callback and marks the
    # collector as finished. Any subsequent calls to :<< will raise an error.
    def finish
      Fiber.new do
        flush(&@callback)
        @finished = true
        Fiber.yield
      end.resume
    end

    # Yields the collected rows and resets the row collector
    # @yield [Array<Hash>] The collected rows
    def flush
      error = false
      yield @rows
    rescue Exception => e
      error = true
      raise e
    ensure
      @rows = [] unless error
    end
  end
end
