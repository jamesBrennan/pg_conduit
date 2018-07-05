module PgConduit
  # A thread safe accumulator, used to chunk an input stream
  class RowCollector
    # @param chunk_size [Integer] How many rows should be collected before
    #   yielding
    def initialize(chunk_size: 100)
      @chunk_size = chunk_size
      @rows = []
      @finished = false
      @mutex = Mutex.new
    end

    # Provide a block to be called with each accumulated chunk
    #
    # @yield [Array] collected rows
    # @return [self]
    #
    # @example Print once every ten rows
    #
    #   collector = RowCollector.new(chunk_size: 10)
    #   collector.on_chunk { |rows| puts rows }
    #
    #   100.times { |n| collector << n }
    #
    #   #> [0,1,2,3,4,5,6,7,8,9]
    #   #> [10,11,12,13,14,15,16,17,18,19]
    #   #> ...etc
    #
    def on_chunk(&callback)
      self.tap do
        @mutex.synchronize { @callback = callback }
      end
    end

    # @param row [Object] Row to add to the buffer
    def <<(row)
      @mutex.synchronize do
        if @finished
          raise 'Data may not be added to a row collector that has been marked as finished'
        end

        @rows << row
        if @rows.length % @chunk_size == 0
          flush(&@callback)
        end
      end
    end

    # Flushes any collected rows, yielding them to the callback and marks the
    # collector as finished. Any subsequent calls to :<< will raise an error.
    def finish
      @mutex.synchronize do
        flush(&@callback)
        @finished = true
      end
    end

    private

    # Yields the collected rows and resets the row collector
    # @yield [Array<Hash>] The collected rows
    def flush
      yield @rows if @rows.length > 0
      @rows = []
      true
    end
  end
end
