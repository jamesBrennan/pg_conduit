
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pg_conduit/version'

Gem::Specification.new do |spec|
  spec.name          = 'pg_conduit'
  spec.version       = PgConduit::VERSION
  spec.authors       = ['James Brennan']
  spec.email         = ['brennanmusic@gmail.com']

  spec.summary       = 'Stream data from one postgres database to another'
  spec.homepage      = 'https://github.com/jamesBrennan/pg_conduit'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'pg', '~> 1.0'
  spec.add_dependency 'connection_pool', '~> 2.2'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.4.1'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'guard', '~> 2.14'
  spec.add_development_dependency 'guard-rspec'
end
