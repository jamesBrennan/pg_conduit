module PgConduit
  # Execute a SQL query and provide the results as a stream
  # @example Print username and email for all users
  #
  #   conn    = PG::Connection.open
  #   stream  = PgConduit::QueryStream.new(conn)
  #
  #   stream.query('SELECT * FROM users').each_row do |row|
  #     puts "#{row['username']}, #{row['email']}"
  #   end
  #
  class QueryStream
    attr_reader :sql

    # @param pool [ConnectionPool] A pool of PG::Connections
    def initialize(pool)
      @pool = pool
    end

    # @param sql [String] The SQL query to execute
    # @return [self]
    def query(sql)
      self.tap { @sql = sql }
    end

    # Execute query and yield each row
    # @yield [Hash] A hash representing a single row from the result set
    def each_row
      @pool.with do |conn|
        conn.send_query @sql
        conn.set_single_row_mode
        conn.get_result.stream_each do |row|
          yield row
        end
      end
    end
  end
end
