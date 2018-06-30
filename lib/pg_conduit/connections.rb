require 'connection_pool'

module PgConduit
  class Connections
    def initialize(source, destination)
      @src_pool = init_pool(source)
      @dest_pool = init_pool(destination)
    end

    def with_source
      @src_pool.with { |conn| yield conn }
    end

    def with_destination
      @dest_pool.with { |conn| yield conn }
    end

    private

    def init_pool(params)
      ConnectionPool.new { PG::Connection.open(params) }
    end
  end
end
