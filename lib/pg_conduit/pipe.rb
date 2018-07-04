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
      @transformers = []
    end

    def read(query)
      self.tap { @stream.query(query) }
    end

    def transform(&formatter)
      self.tap { @transformers << formatter }
    end

    def write
      exec_read { |row| exec_write { exec_transform(row) } }
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

    private

    def exec_read(&b)
      @reader.read(&b)
    end

    def exec_write(&b)
      @writer.write(&b)
    end

    def exec_transform(row)
      @transformers.reduce(row) { |r, transform| transform.call(r) }
    end
  end
end
