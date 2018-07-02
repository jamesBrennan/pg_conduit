require 'spec_helper'

module PgConduit
  ::RSpec.describe Pipe do
    let(:src) { ENV.fetch('TEST_DB_SRC') }
    let(:dest) { ENV.fetch('TEST_DB_DEST') }

    let(:connections) { Connections.new(src, dest) }
    let(:stream) { QueryStream.new(connections.src_pool) }
    let(:writer) { DBWriter.new(connections.dest_pool) }

    before do
      with_connection src do |conn|
        conn.exec <<-SQL
        DROP TABLE IF EXISTS people;
        CREATE TABLE people (
          full_name character varying,
          dob date
        );
        SQL
      end

      with_connection dest do |conn|
        conn.exec <<-SQL
        DROP TABLE IF EXISTS friends;
        CREATE TABLE friends (
          full_name character varying,
          age integer
        );
        SQL
      end
    end

    describe 'processing one row at a time' do
      before do
        with_connection src do |conn|
          conn.exec <<-SQL
          INSERT INTO people (full_name, dob)
          VALUES
            ('Robert Oppenheimer', '1904-04-22'),
            ('John Muir', '1838-04-21')
          SQL
        end
      end

      it 'works' do
        described_class
          .new(from: stream, to: writer)
          .send('SELECT * FROM people')
          .as do |person|
          <<-SQL
            INSERT INTO friends (full_name, age)
            VALUES (
              '#{person['full_name']}', 
              EXTRACT(YEAR FROM age('#{person['dob']}'::timestamp))
            )
          SQL
        end

        with_connection dest do |conn|
          res = conn.exec('SELECT count(*) FROM friends')
          expect(res[0]).to eql('count' => '2')
        end
      end
    end

    describe 'processing rows in chunks' do
      let(:people) {
        100.times.map do |n|
          %(('Person #{n}', '1990-04-#{(n % 30) + 1}'))
        end.join(',')
      }

      before do
        with_connection src do |conn|
          conn.exec <<-SQL
          DELETE FROM people;        

          INSERT INTO people (full_name, dob)
          VALUES #{people};
          SQL
        end

        with_connection dest do |conn|
          conn.exec <<-SQL
          DELETE FROM friends;
          SQL
        end
      end

      it 'works' do
        described_class
          .new(from: stream, to: writer)
          .send('SELECT * FROM people')
          .as_chunked(
            size: 10,
            prefix: 'INSERT INTO friends (full_name, age) VALUES') do |person|
          %(('#{person['full_name']}', EXTRACT(YEAR FROM age('#{person['dob']}'::timestamp))))
        end

        with_connection dest do |conn|
          res = conn.exec('SELECT count(*) FROM friends')
          expect(res[0]).to eql('count' => '100')
        end
      end
    end
  end
end
