require 'pg'
require 'connection_pool'

require 'pg_conduit/version'

module PgConduit
  autoload :QueryStream, 'pg_conduit/query_stream'
  autoload :StreamDispatcher, 'pg_conduit/stream_dispatcher'
end
