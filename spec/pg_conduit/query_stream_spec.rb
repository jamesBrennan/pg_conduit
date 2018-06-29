require 'spec_helper'

RSpec.describe PgConduit::QueryStream do
  SRC_URL = 'postgres://postgres@db/pg_conduit_src_test'

  def with_stream
    with_connection SRC_URL do |conn|
      yield PgConduit::QueryStream.new(conn)
    end
  end

  describe '.query' do
    it 'sets the value of @sql' do
      with_stream do |stream|
        stream.query 'SELECT 1'
        expect(stream.sql).to eql 'SELECT 1'
      end
    end

    it 'returns self' do
      with_stream do |stream|
        expect(stream.query('')).to eql stream
      end
    end
  end

  describe '.each_row' do
    before do
      with_connection(SRC_URL) do |conn|
        conn.exec <<-SQL
          DROP TABLE IF EXISTS people;
          CREATE TABLE people (
            full_name character varying,
            dob date
          );
  
          INSERT INTO people (full_name, dob)
          VALUES
            ('Robert Oppenheimer', '1904-04-22'),
            ('John Muir', '1838-04-21')
        SQL
      end
    end

    it 'yields each row' do
      with_stream do |stream|
        expect { |b| stream.query('select * from people').each_row(&b) }.to(
          yield_successive_args(
            { 'full_name' => 'Robert Oppenheimer', 'dob' => '1904-04-22' },
            { 'full_name' => 'John Muir', 'dob' => '1838-04-21' }
          )
        )
      end
    end
  end
end
