require 'pg'
require 'connection_pool'
require 'pg_conduit/version'

module PgConduit
  autoload :Connections,          'pg_conduit/connections'
  autoload :DBWriter,             'pg_conduit/db_writer'
  autoload :ParallelStreamReader, 'pg_conduit/parallel_stream_reader'
  autoload :Pipe,                 'pg_conduit/pipe'
  autoload :QueryStream,          'pg_conduit/query_stream'
  autoload :RowCollector,         'pg_conduit/row_collector'
end
