module PgConduit
  class DBWriter
    def initialize(pool)
      @pool = pool
    end

    def write(line)
      @pool.with { |conn| conn.exec line }
    end
  end
end
