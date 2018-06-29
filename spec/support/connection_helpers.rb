require 'pg'

module ConnectionHelpers
  def with_connection(params)
    conn = PG::Connection.open(params)
    yield conn
  ensure
    conn&.close
  end
end
