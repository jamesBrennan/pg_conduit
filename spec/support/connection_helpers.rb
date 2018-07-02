require 'pg'
require 'connection_pool'

module ConnectionHelpers
  def with_connection(params)
    conn = PG::Connection.open(params)
    yield conn
  ensure
    conn&.close
  end

  def with_pool(params)
    ConnectionPool.new { PG::Connection.open(params) }
  end
end
