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

    def send(query)
      self.tap { @stream.query(query) }
    end

    def as(&formatter)
      self.tap { @row_formatter = formatter }
    end

    def exec
      read { |row| write { @row_formatter.call(row) } }
    end

    def exec_batched(size: 1000)
      collector = RowCollector.new(chunk_size: size)

      # Set callback to yield collected rows
      collector.on_chunk { |rows| write { yield rows } }

      # Process each row
      read { |row| collector << @row_formatter.call(row) }

      # Yield any remaining rows
      collector.finish
    end

    private

    def read(&b)
      @reader.read(&b)
    end

    def write(&b)
      @writer.write(&b)
    end
  end
end
