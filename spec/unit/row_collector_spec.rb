require 'spec_helper'

RSpec.describe PgConduit::RowCollector do
  subject(:collector) do
    described_class.new(chunk_size: chunk_size)
  end

  describe '.on_chunk' do
    let(:chunk_size) { 10 }

    it 'yields every N rows' do
      expect { |b|
        collector.on_chunk(&b)
        20.times { collector << 1 }
      }.to yield_control.exactly(2).times
    end

    it 'yields an array of collected values' do
      expect { |b|
        collector.on_chunk(&b)
        10.times { |n| collector << n }
      }.to yield_with_args((0..9).to_a)
    end
  end
end
