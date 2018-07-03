module PgConduit
  class Pipe
    # @example
    #   Pipe
    #     .new(from: query_stream, to: db_writer)
    #     .send('SELECT name FROM users')
    #     .as do |user|
    #       %(INSERT INTO friends (name) VALUES ('#{user["full_name"]}'))
    #     end
    def initialize(from:, to:)
      @stream = from
      @writer = to
      @reader = ParallelStreamReader.new(@stream)
      @row_formatter = lambda { |row| row }
    end

    def read(query)
      self.tap { @stream.query(query) }
    end

    def transform(&formatter)
      self.tap { @row_formatter = formatter }
    end

    def write
      exec_read { |row| exec_write { @row_formatter.call(row) } }
    end

    def write_batched(size: 1000)
      collector = RowCollector.new(chunk_size: size)

      # Set callback to yield collected rows
      collector.on_chunk { |rows| exec_write { yield rows } }

      # Process each row
      exec_read { |row| collector << @row_formatter.call(row) }

      # Yield any remaining rows
      collector.finish
    end

    private

    def exec_read(&b)
      @reader.read(&b)
    end

    def exec_write(&b)
      @writer.write(&b)
    end
  end
end
