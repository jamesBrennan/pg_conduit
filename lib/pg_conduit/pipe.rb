require 'pg_conduit/connections'
require 'pg_conduit/query_stream'
require 'pg_conduit/parallel_stream_reader'

module PgConduit
  class Pipe
    # @example
    #   Pipe
    #     .new(from: 'postgres://remote_db', to: 'postgres://local_db')
    #     .send('SELECT name FROM users')
    #     .as do |user|
    #       %(INSERT INTO friends (name) VALUES ('#{user["full_name"]}'))
    #     end

    def initialize(from: nil, to: nil)
      @src = from
      @dest = to
    end

    def from(source)
      self.tap { @src = source }
    end

    def to(destination)
      self.tap { @dest = destination }
    end

    def send(query)
      self.tap { @query = query }
    end

    def as
      with_query_stream do |stream|
        read(stream) { |row| destination_exec yield(row) }
      end
    end

    private

    def connections
      @connections ||= Connections.new(@src, @dest)
    end

    def with_query_stream
      connections.with_source do |conn|
        yield QueryStream.new(conn).query(@query)
      end
    end

    def read(stream)
      ParallelStreamReader.new.process(stream) do |row|
        yield row
      end
    end

    def destination_exec(sql)
      connections.with_destination { |conn| conn.exec sql }
    end
  end
end
