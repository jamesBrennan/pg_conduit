require 'rspec/expectations'

RSpec::Matchers.define :run_in_fewer_seconds_than do |seconds|
  match do |proc|
    t1 = Time.now
    proc.call
    t2 = t1 - Time.now
    t2 < seconds
  end

  supports_block_expectations
end
