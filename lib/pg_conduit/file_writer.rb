module PgConduit
  class FileWriter
    def initialize(path)
      @path = path
    end

    def write
      open(@path, 'a') { |f| f.puts yield }
    end
  end
end
