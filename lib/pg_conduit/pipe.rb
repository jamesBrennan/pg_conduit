module PgConduit
  class Pipe
    # @example
    #   Pipe
    #     .new(from: query_stream, to: db_writer)
    #     .read('SELECT name FROM users')
    #     .transform do |user|
    #       %(INSERT INTO friends (name) VALUES ('#{user["full_name"]}'))
    #     end
    #     .run
    def initialize(from:, to:)
      @stream               = from
      @writer               = to
      @reader               = Parallelize.new(max_concurrency: 5).call(@stream)
      @transformers         = []
      @collector            = nil
      @on_chunk             = nil
      @results              = Queue.new
    end

    def read(query)
      self.tap { @stream.select(query) }
    end

    def transform(*transformers, &transformer)
      self.tap do
        @transformers.concat(transformers)
        @transformers << transformer if block_given?
      end
    end

    def on_chunk(size: 1000, &b)
      self.tap do
        @collector = RowCollector.new(chunk_size: size)
        @collector.on_chunk do |chunk|
          input   = b.call chunk
          result  = exec_write { input }
          @results << [input, result]
        end
      end
    end

    def run
      run_thread      = start_run
      notifier_thread = start_notifier { |msg| yield msg if block_given? }
      run_thread.join
      notifier_thread.join
    end

    def peak
      self.tap { @transformers << ->(row) { row.tap { yield row } } }
    end

    private

    def start_run
      Thread.new do
        if @collector
          run_batched
        else
          run_single
        end
      ensure
        @results.close
      end
    end

    def run_batched
      exec_read { |row| @collector << exec_transform(row) }
    ensure
      @collector.finish
    end

    def run_single
      exec_read do |row|
        input  = exec_transform row
        result = exec_write { input }
        @results << [input, result]
      end
    end

    def start_notifier
      Thread.new do
        loop do
          break if @results.closed? && @results.empty?
          msg = @results.deq
          yield msg if msg
        end
      end
    end

    def exec_read(&b)
      @reader.each(&b)
    end

    def exec_write(&b)
      @writer.write(&b)
    rescue StandardError => e
      e
    end

    def exec_transform(row)
      @transformers.reduce(row) { |data, transform| transform.call data }
    end
  end
end
