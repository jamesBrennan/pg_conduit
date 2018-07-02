module PgConduit
  class STDOUTWriter
    def write
      puts yield
    end
  end
end
