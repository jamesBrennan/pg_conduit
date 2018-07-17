require 'connection_pool'

module PgConduit
  class Parallelize
    def initialize(max_concurrency: 100, max_messages: 1000)
      @queue = SizedQueue.new(max_messages)
      @concurrency = max_concurrency
      @lock = Mutex.new
    end

    def call(enumerable)
      input = Thread.new {
        enumerable.each { |o| @queue << o }
        @queue.close
      }

      Enumerator.new do |yielder|
        workers = (1..@concurrency).to_a.map { dispatch_worker(yielder) }
        input.join
        workers.each { |t| t.join }
      end
    end

    private

    def dispatch_worker(yielder)
      Thread.new do
        loop do
          message = @queue.deq
          break if @queue.closed? && !message
          next unless message
          yielder << message
        end
      end
    end
  end
end
