module PgConduit
  class NullWriter
    def write
      yield
    end
  end
end
