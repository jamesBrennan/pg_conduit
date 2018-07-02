module PgConduit
  class DBWriter
    def initialize(pool)
      @pool = pool
    end

    def write
      @pool.with { |conn| conn.exec yield }
    end
  end
end
