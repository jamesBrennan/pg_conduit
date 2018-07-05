require 'simplecov'

if ENV['CI'] == 'true'
  SimpleCov.coverage_dir('/tmp/coverage')
else
  local_dir = File.join File.dirname(__FILE__), '..', '..', 'coverage'
  SimpleCov.coverage_dir local_dir
end

SimpleCov.start do
  add_filter %r{_spec\.rb$}
end
