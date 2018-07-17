module PgConduit
  class DBWriter
    def initialize(pool)
      @pool = pool
    end

    def write
      @pool.with { |conn| conn.exec yield }
    end

    def call(enumerable)
      Enumerator.new do |yielder|
        enumerable.each { |query| yielder << exec(query) }
      end
    end

    private

    def exec(query)
      @pool.with { |conn| conn.exec query }
    rescue PG::Error => error
      error
    end
  end
end
