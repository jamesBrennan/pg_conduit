require 'pg_conduit/connections'
require 'pg_conduit/query_stream'
require 'pg_conduit/parallel_stream_reader'
require 'pg_conduit/db_writer'

module PgConduit
  class Pipe
    # @example
    #   Pipe
    #     .new(from: 'postgres://remote_db', to: 'postgres://local_db')
    #     .send('SELECT name FROM users')
    #     .as do |user|
    #       %(INSERT INTO friends (name) VALUES ('#{user["full_name"]}'))
    #     end
    def initialize(from:, to:)
      @connections = Connections.new(from, to)
      @stream = QueryStream.new(@connections.src_pool)
      @writer = DBWriter.new(@connections.dest_pool)
    end

    def send(query)
      self.tap { @stream.query(query) }
    end

    def as
      read(@stream) { |row| write yield(row) }
    end

    def as_chunked(size: 1000, prefix: nil)
      collector = RowCollector.new(chunk_size: size)
      collector.on_chunk do |rows|
        write [prefix, rows.join(',')].join(' ')
      end

      read(@stream) { |row| collector << yield(row) }

      collector.finish
    end

    private

    def read(stream)
      ParallelStreamReader.new.process(stream) { |row| yield row }
    end

    def write(line)
      @writer.write line
    end
  end
end
