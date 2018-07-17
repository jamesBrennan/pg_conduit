module PgConduit
  class FileWriter
    def initialize(path)
      @path = path
    end

    def write
      open(@path, 'a') { |f| f.puts yield }
    end

    def call(enum)
      Enumerator.new do |yielder|
        open(@path, 'a') do |f|
          enum.each do |line|
            f.puts line
            yielder << line
          end
        end
      end
    end
  end
end
