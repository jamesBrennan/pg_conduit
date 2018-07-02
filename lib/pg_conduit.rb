require 'pg'
require 'connection_pool'
require 'pg_conduit/version'

module PgConduit
  autoload :Connections,          'pg_conduit/connections'
  autoload :DBWriter,             'pg_conduit/db_writer'
  autoload :FileWriter,           'pg_conduit/file_writer'
  autoload :ParallelStreamReader, 'pg_conduit/parallel_stream_reader'
  autoload :Pipe,                 'pg_conduit/pipe'
  autoload :QueryStream,          'pg_conduit/query_stream'
  autoload :RowCollector,         'pg_conduit/row_collector'

  class << self
    # Create a new DB -> DB Pipe
    #
    # @param src [String,Hash] Connection params to source database
    # @param dest [String,Hash] Connection params to destination database
    # @return [PgConduit::Pipe]
    def db_to_db(src, dest)
      connections   = Connections.new src, dest
      query_stream  = QueryStream.new connections.src_pool
      db_writer     = DBWriter.new connections.dest_pool

      Pipe.new from: query_stream, to: db_writer
    end

    # Create a new DB -> File Pipe
    #
    # @param src [String,Hash] Connection params to source database
    # @param dest [Sting,Pathname] Path to destination file
    # @return [PgConduit::Pipe]
    def db_to_file(src, dest)
      pool          = Connections.init_pool src
      query_stream  = QueryStream.new pool
      file_writer   = FileWriter.new dest

      Pipe.new from: query_stream, to: file_writer
    end
  end
end
