require 'connection_pool'

module PgConduit
  class Connections
    attr_reader :src_pool, :dest_pool

    def self.init_pool(params)
      ConnectionPool.new { PG::Connection.open(params) }
    end

    def initialize(source, destination)
      @src_pool   = self.class.init_pool source
      @dest_pool  = self.class.init_pool destination
    end

    def with_source
      @src_pool.with { |conn| yield conn }
    end

    def with_destination
      @dest_pool.with { |conn| yield conn }
    end
  end
end
