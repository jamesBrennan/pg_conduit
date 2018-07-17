require 'spec_helper'

RSpec.describe PgConduit::Parallelize do
  subject(:parallelize) { described_class.new(max_concurrency: max) }
  let(:max) { 100 }

  describe '.call' do
    subject(:call) { parallelize.call(input) }

    let(:input) { [] }

    it { is_expected.to be_a Enumerator }

    describe 'enumerating' do
      let(:input) { (1..100).to_a }

      it 'yields once for each element' do
        expect { |b| call.each(&b) }.to yield_control.exactly(100).times
      end
    end

    describe 'concurrency' do
      let(:max) { 10 }
      let(:input) { (1..10).to_a }

      it 'works as expected' do
        expect { call.each { sleep(0.25) } }.to run_in_fewer_seconds_than 0.28
      end
    end
  end
end
