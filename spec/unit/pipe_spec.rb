require 'spec_helper'
require 'tempfile'

RSpec.describe PgConduit::Pipe do
  subject(:pipe) { described_class.new(from: stream, to: writer) }

  let(:stream) { PgConduit::EnumStream.new(input) }
  let(:writer) { PgConduit::NullWriter.new }
  let(:input) { [1,2,3] }

  describe '.peak' do
    it 'yields the output of the step before it' do
      expect { |b| pipe.peak(&b).transform(->(x) { x * x }).peak(&b).run }.to(
        yield_successive_args 1, 1, 2, 4, 3, 9
      )
    end

    it 'does not modify the data stream' do
      expect { |b| pipe.peak { |x| x * x }.peak(&b).run }.to (
        yield_successive_args 1, 2, 3
      )
    end
  end

  describe '.transform' do
    subject(:transformed) { pipe.transform(*args, &block) }

    let(:args) { [->(x) { x + 1 }] }
    let(:block) { nil }

    it 'returns self' do
      expect(transformed).to eql(pipe)
    end

    it 'applies the transformations when .run is called' do
      expect { |b| transformed.peak(&b).run }.to (
        yield_successive_args 2, 3, 4
      )
    end

    context 'when a transformer is a class' do
      let(:transformer) do
        Class.new do
          def self.call(input)
            [input, input + input]
          end
        end
      end

      let(:args) { [transformer] }

      it 'applies the transformations' do
        expect { |b| transformed.peak(&b).run }.to(
          yield_successive_args [1,2], [2,4], [3,6]
        )
      end
    end

    describe 'calling with multiple transformations' do
      let(:args) {
        [
          -> (x) { x * 2 },
          -> (x) { x.to_s }
        ]
      }

      it 'applies the transformations in the order specified' do
        expect { |b| transformed.peak(&b).run }.to(
          yield_successive_args '2', '4', '6'
        )
      end
    end
  end
end