require 'spec_helper'
require 'tempfile'

module PgConduit
  ::RSpec.describe Pipe do
    let(:src) { ENV.fetch('TEST_DB_SRC') }
    let(:dest) { ENV.fetch('TEST_DB_DEST') }

    let(:connections) { Connections.new(src, dest) }
    let(:stream) { QueryStream.new(connections.src_pool) }
    let(:writer) { DBWriter.new(connections.dest_pool) }

    subject(:pipe) { described_class.new(from: stream, to: writer) }

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

      describe 'writing to another database' do
        it 'works' do
          insert_row = lambda { |person|
            <<-SQL
              INSERT INTO friends (full_name, age)
              VALUES (
                '#{person['full_name']}',
                EXTRACT(YEAR FROM age('#{person['dob']}'::timestamp))
              )
            SQL
          }

          pipe.read('SELECT * FROM people').transform(&insert_row).run

          with_connection dest do |conn|
            res = conn.exec('SELECT count(*) FROM friends')
            expect(res[0]).to eql('count' => '2')
          end
        end
      end

      describe 'writing to a file' do
        let(:file) { Tempfile.new }
        let(:writer) { FileWriter.new(file.path) }

        it 'works' do
          pipe.read('SELECT * FROM people')
              .transform { |row| "#{row['dob']} | #{row['full_name']}" }
              .run

          expect(File.readlines(file.path)).to contain_exactly(
            %(1838-04-21 | John Muir\n),
            %(1904-04-22 | Robert Oppenheimer\n)
          )
        ensure
          file.close
          file.unlink
        end
      end
    end

    describe 'observing the data flow' do
      let(:writer) { NullWriter.new }

      before do
        with_connection src do |conn|
          conn.exec <<-SQL
            INSERT INTO people (full_name)
            VALUES ('John Muir')
          SQL
        end
      end

      it 'yields the row with preceding transforms applied' do
        expect { |b|

          pipe
            .read('SELECT * FROM people')
            .peak(&b)
            .transform { |row| row['full_name'] }
            .peak(&b)
            .transform { |name| name.upcase  }
            .peak(&b)
            .run

        }.to(
          yield_successive_args(
            # The first peak is before the transform, we get row data
            { 'full_name' => 'John Muir', 'dob' => nil },

            # The next peak is after the transform, we get the name
            'John Muir',

            # And so on ...
            'JOHN MUIR'
          )
        )

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
        values_formatter = lambda { |person|
          <<-SQL
            ('#{person['full_name']}',
             EXTRACT(YEAR FROM age('#{person['dob']}'::timestamp)))
          SQL
        }

        pipe.read('SELECT * FROM people')
            .transform(&values_formatter)
            .on_chunk(size: 10) do |values|
              <<-SQL
                INSERT INTO friends (full_name, age) 
                VALUES #{values.join(',')}
              SQL
            end
            .run

        with_connection dest do |conn|
          res = conn.exec('SELECT count(*) FROM friends')
          expect(res[0]).to eql('count' => '100')
        end
      end
    end
  end
end
