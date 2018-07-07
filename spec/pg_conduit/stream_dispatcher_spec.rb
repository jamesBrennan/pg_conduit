require 'spec_helper'

RSpec.describe PgConduit::ParallelStreamReader do
  subject(:reader) { described_class.new(query_stream) }

  let(:query_stream) { instance_double(PgConduit::QueryStream) }

  before do
    allow(query_stream).to receive(:query).and_return(query_stream)
  end

  it 'yields each row in the stream' do
    expect(query_stream).to(
      receive(:each).tap do |exp|
        100.times do |n|
          exp.and_yield("row_#{n}")
        end
        exp.and_yield(nil)
      end
    )
    expect { |b|
      reader.read(&b)
    }.to yield_control.exactly(100).times
  end
end
