require 'simplecov'
SimpleCov.coverage_dir('/src/coverage')
SimpleCov.start do
  add_filter %r{_spec\.rb$}
end
