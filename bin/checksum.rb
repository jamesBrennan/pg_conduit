#!/usr/bin/env ruby
require 'digest/sha2'
require 'pg_conduit/version'

gem_name = "pg_conduit-#{PgConduit::VERSION}.gem"
checksum = Digest::SHA512.new.hexdigest File.read("pkg/#{gem_name}")
File.open("checksum/#{gem_name}.sha512", 'w' ) do |f|
  f.write checksum
end
