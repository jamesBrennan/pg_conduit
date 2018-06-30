module PgConduit
  # Async stream processor
  class StreamDispatcher
    def initialize(workers: 5)
      @queue = Queue.new
      @workers = workers
    end

    def process_query_stream(query_stream, &callback)
      reader = read_stream(query_stream)
      workers = dispatch_workers(&callback)
      reader.join
      workers.each { |t| t.join }
    end

    private

    def read_stream(query_stream)
      Thread.new do
        query_stream.each_row { |row| enqueue(row) }
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

    def enqueue(row)
      Fiber.new do
        while apply_back_pressure?; end
        @queue << row
        Fiber.yield
      end.resume
    end

    def process_next(&callback)
      Fiber.new do
        row = @queue.deq
        Fiber.yield unless row
        callback.call row
        Fiber.yield true
      end.resume
    end

    def apply_back_pressure?
      @queue.size > 1000
    end
  end
end
