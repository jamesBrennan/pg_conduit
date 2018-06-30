require 'spec_helper'

RSpec.describe PgConduit::Pipe do
  let(:src) { ENV.fetch('TEST_DB_SRC') }
  let(:dest) { ENV.fetch('TEST_DB_DEST') }

  before do
    with_connection src do |conn|
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

  it 'sends the data' do
    described_class
      .new(from: src, to: dest)
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
