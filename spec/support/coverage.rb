require 'simplecov'

if ENV['CI'] == 'true'
  SimpleCov.coverage_dir('/tmp/coverage')
else
  local_dir = File.join __dir__, '..', '..', 'coverage'
  SimpleCov.coverage_dir local_dir
end

SimpleCov.start do
  add_filter %r{_spec\.rb$}
end
