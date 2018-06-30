require 'pg'
require 'connection_pool'

require 'pg_conduit/version'

module PgConduit
  autoload :Builder,              'pg_conduit/builder'
  autoload :Connections,          'pg_conduit/connections'
  autoload :ParallelStreamReader, 'pg_conduit/parallel_stream_reader'
  autoload :QueryStream,          'pg_conduit/query_stream'
  autoload :RowCollector,         'pg_conduit/row_collector'
end
