require 'pg'
require 'connection_pool'

require 'pg_conduit/version'

module PgConduit
  autoload :QueryStream, 'pg_conduit/query_stream'
  autoload :ParallelStreamReader, 'pg_conduit/parallel_stream_reader'
  autoload :RowCollector, 'pg_conduit/row_collector'
end
