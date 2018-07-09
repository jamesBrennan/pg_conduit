require 'spec_helper'
require 'tempfile'

RSpec.describe PgConduit::Pipe do
  let(:subject) { described_class.new(from: from, to: to) }
  let(:from) { Queue.new }
  let(:to) { PgConduit::NullWriter.new }


end