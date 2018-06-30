require 'spec_helper'

RSpec.describe PgConduit::RowCollector do
  subject(:collector) { described_class.new }

  describe '.every' do
    it 'yields every N rows' do
      expect { |b|
        collector.every(10, &b)
        20.times { collector << 1 }
      }.to yield_control.exactly(2).times
    end

    it 'yields an array of collected values' do
      expect { |b|
        collector.every(2, &b)
        collector << 1
        collector << 2
      }.to yield_with_args([1,2])
    end
  end
end
