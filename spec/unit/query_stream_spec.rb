require 'spec_helper'

def with_stream
  with_pool ENV.fetch('TEST_DB_SRC') do |pool|
    yield PgConduit::QueryStream.new(pool)
  end
end

RSpec.describe PgConduit::QueryStream do
  describe '.query' do
    it 'sets the value of @sql' do
      with_stream do |stream|
        stream.select 'SELECT 1'
        expect(stream.sql).to eql 'SELECT 1'
      end
    end

    it 'returns self' do
      with_stream do |stream|
        expect(stream.select('')).to eql stream
      end
    end
  end

  describe '.call' do
    before do
      with_connection ENV.fetch('TEST_DB_SRC') do |conn|
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
        expect { |b| stream.call('select * from people', &b) }.to(
          yield_successive_args(
            { 'full_name' => 'Robert Oppenheimer', 'dob' => '1904-04-22' },
            { 'full_name' => 'John Muir', 'dob' => '1838-04-21' }
          )
        )
      end
    end
  end
end
