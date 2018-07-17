require 'spec_helper'
require 'fileutils'

RSpec.describe PgConduit::FileWriter do
  subject(:writer) { described_class.new(path) }

  let(:path) { File.expand_path('test-file.txt', __dir__) }
  let(:lines) { ['a', 'b', 'c'] }

  before do
    FileUtils.touch path
  end

  after do
    File.delete(path)
  end

  it 'writes each enum member as a line' do
    writer.call(lines).lazy.force
    expect(File.readlines(path)).to(
      contain_exactly *lines.map { |ln| "#{ln}\n" }
    )
  end
end
