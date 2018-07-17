module PgConduit
  # A multi threaded stream reader
  class ParallelStreamReader
    # @param query_stream [PgConduit::QueryStream]
    # @param threads [Integer] The number of threads to use for workers
    # @param queue_max_size [Integer] How many rows should be stored in memory
    #   in the work queue.
    def initialize(query_stream, threads: 5, queue_max_size: 1000)
      @reader = Parallelize
                  .new(max_concurrency: threads, max_messages: queue_max_size)
                  .call(query_stream)
    end

    # Read A QueryStream and yield it's rows
    #
    # @yield [Hash] A single row from the QueryStream. Every row from the stream
    #   will be yielded but order is not guaranteed.
    def read(&callback)
      @reader.each(&callback)
      :ok
    end
  end
end
