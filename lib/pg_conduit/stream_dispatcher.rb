module PgConduit
  # Async stream processor
  class StreamDispatcher
    # @param pool [ConnectionPool]
    def initialize(pool, workers: 5)
      @pool = pool
      @queue = Queue.new
      @all_rows_queued = false
      @workers = workers
    end

    def process_query_stream(query_stream, &callback)
      read = Thread.new do
        query_stream.each_row { |row| enqueue(row) }
        @all_rows_queued = true
      end

      # worker_threads = (1..@workers).to_a.map do
      #   Thread.new do
      #     loop do
      #       row, _result = process_next(&callback)
      #       break if @all_rows_queued && !row
      #     end
      #   end
      # end

      process = Thread.new do
        loop do
          row, _result = process_next(&callback)
          break if @all_rows_queued && !row
        end
      end

      read.join
      process.join
      # worker_threads.each { |t| t.join }
    end

    private

    def enqueue(row)
      Fiber.new do
        while @queue.size > 100; end
        @queue << row
        Fiber.yield
      end.resume
    end

    def process_next(&callback)
      Fiber.new do
        row = @queue.deq
        result = row ? callback.call(row) : nil
        Fiber.yield [row, result]
      end.resume
    end
  end
end
