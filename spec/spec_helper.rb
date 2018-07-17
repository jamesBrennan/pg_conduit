require 'bundler/setup'
require 'support/coverage'
require 'pg_conduit'
require 'support/connection_helpers'
require 'support/matchers'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  # config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include ConnectionHelpers
end
