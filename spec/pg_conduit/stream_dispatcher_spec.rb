require 'spec_helper'

RSpec.describe PgConduit::StreamDispatcher do
  subject(:dispatcher) { described_class.new(pool) }
  let(:pool) { instance_double(ConnectionPool) }

  let(:query_stream) { instance_double(PgConduit::QueryStream) }

  before do
    allow(query_stream).to receive(:query).and_return(query_stream)
  end

  it 'yields each row in the stream' do
    expect(query_stream).to(
      receive(:each_row).tap do |exp|
        200.times do |n|
          exp.and_yield("row_#{n}")
        end
        exp.and_yield(nil)
      end
    )
    expect { |b|
      dispatcher.process_query_stream(query_stream, &b)
    }.to yield_control.exactly(200).times
  end
end
