module PgConduit
  class DBWriter
    def initialize(pool)
      @pool = pool
    end

    def write
      @pool.with { |conn| conn.exec yield }
    end

    def call(enumerable)
      return enum_for(:call, enumerable) unless block_given?
      enumerable.each { |query| yield exec(query) }
    end

    private

    def exec(query)
      @pool.with { |conn| conn.exec query }
    rescue PG::Error => error
      error
    end
  end
end
