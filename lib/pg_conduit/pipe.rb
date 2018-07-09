module PgConduit
  class Pipe
    # @example
    #   Pipe
    #     .new(from: query_stream, to: db_writer)
    #     .read('SELECT name FROM users')
    #     .transform do |user|
    #       %(INSERT INTO friends (name) VALUES ('#{user["full_name"]}'))
    #     end
    #     .exec
    def initialize(from:, to:)
      @stream = from
      @writer = to
      @reader = ParallelStreamReader.new(@stream)
      @transformers = []
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

    def write
      exec_read { |row| exec_write { exec_transform(row) } }
    end

    def run
      exec_read do |row|
        result = exec_write { exec_transform(row) }
        yield result if block_given?
      end
    end

    def peak
      self.tap { @transformers << ->(row) { row.tap { yield row } } }
    end

    def write_batched(size: 1000)
      collector = RowCollector.new(chunk_size: size)

      # Set callback to yield collected rows
      collector.on_chunk { |rows| exec_write { yield rows } }

      # Process each row
      exec_read { |row| collector << exec_transform(row) }

      # Yield any remaining rows
      collector.finish
    end

    alias_method :exec, :write

    private

    def exec_read(&b)
      @reader.read(&b)
    end

    def exec_write(&b)
      @writer.write(&b)
    end

    def exec_transform(row)
      @transformers.reduce(row) { |data, transform| transform.call data }
    end
  end
end
