module PgConduit
  # A multi threaded stream reader
  class ParallelStreamReader
    # @param threads [Integer] The number of threads to use for workers
    # @param queue_max_size [Integer] How many rows should be stored in memory
    #   in the work queue.
    def initialize(threads: 5, queue_max_size: 1000)
      @queue = SizedQueue.new(queue_max_size)
      @workers = threads
    end

    # Read A QueryStream and yield it's rows
    #
    # @param query_stream [PgConduit::QueryStream] The query stream to read
    # @yield [Hash] A single row from the QueryStream. Every row from the stream
    #   will be yielded but order is not guaranteed.
    def process(query_stream, &callback)
      reader = read_stream(query_stream)
      workers = dispatch_workers(&callback)
      reader.join
      workers.each { |t| t.join }
    end

    private

    def read_stream(query_stream)
      Thread.new do
        query_stream.each_row { |row| @queue << row }
        @queue.close
      end
    end

    def dispatch_workers(&callback)
      (1..@workers).to_a.map { dispatch_worker(&callback) }
    end

    def dispatch_worker(&callback)
      Thread.new do
        loop do
          continue = process_next(&callback)
          break if @queue.closed? && !continue
        end
      end
    end

    def process_next(&callback)
      continue = false
      Thread.new do
        row = @queue.deq
        if row
          callback.call row
          continue = true
        end
      end.join
      continue
    end
  end
end
