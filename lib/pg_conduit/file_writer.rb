module PgConduit
  class FileWriter
    def initialize(path)
      @path = path
    end

    def write
      open(@path, 'a') { |f| f.puts yield }
    end

    def call(enum)
      return enum_for(:call, enum) unless block_given?

      open(@path, 'a') do |f|
        enum.each do |line|
          f.puts line
          yield line
        end
      end
    end
  end
end
