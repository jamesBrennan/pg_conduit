require 'pg_conduit/parallel_stream_reader'

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
    end

    def send(query)
      self.tap { @stream.query(query) }
    end

    def as
      read { |row| write { yield row } }
    end

    def as_chunked(size: 1000, prefix: nil)
      collector = RowCollector.new(chunk_size: size)
      collector.on_chunk do |rows|
        write { [prefix, rows.join(',')].join(' ') }
      end

      read { |row| collector << yield(row) }

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
