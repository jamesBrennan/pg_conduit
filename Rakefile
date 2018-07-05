require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'pg'

def create_db(conn, name)
  conn.exec "CREATE DATABASE #{name}"
rescue PG::DuplicateDatabase
  puts "Create database skipped: '#{name}' already exists."
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :db do
  task :create do
    conn = PG::Connection.open(ENV['TEST_DB_HOST'])
    create_db conn, 'pg_conduit_src_test'
    create_db conn, 'pg_conduit_dest_test'
  ensure
    conn.close
  end
end
