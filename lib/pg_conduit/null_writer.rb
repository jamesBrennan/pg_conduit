module PgConduit
  class NullWriter
    def write
      nil.tap { yield }
    end
  end
end
