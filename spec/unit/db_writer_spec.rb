require 'spec_helper'

RSpec.describe PgConduit::DBWriter do
  subject(:db_writer) { described_class.new(pool) }
  let(:pool) { with_pool ENV['TEST_DB_SRC'] }

  describe '.call' do
    subject(:enumerator) { db_writer.call(input) }

    let(:input) { ['SELECT 1', 'SELECT 2', 'SELECT 3'] }

    it { is_expected.to be_a Enumerator }

    describe 'enumerating over results' do
      it 'yields the result of executing the SQL statement' do
        expect { |b| enumerator.each(&b) }.to(
          yield_successive_args(PG::Result, PG::Result, PG::Result)
        )
      end

      describe 'with a malformed query' do
        let(:input) { ['SELECT 1', 'SELECT * FROM no_such_table', 'SELECT 2'] }

        it 'does not raise an exception' do
          expect { |b| enumerator.each(&b) }.not_to raise_exception
        end

        it 'enumerates over members after the malformed query' do
          expect { |b| enumerator.each(&b) }.to(
            yield_successive_args(PG::Result, PG::Error, PG::Result)
          )
        end
      end
    end
  end
end
