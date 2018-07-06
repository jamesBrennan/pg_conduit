# PgConduit

[![CircleCI](https://img.shields.io/circleci/project/github/jamesBrennan/pg_conduit.svg?style=svg)](https://circleci.com/gh/jamesBrennan/pg_conduit)

Stream data between two postgres databases. This is mostly an excuse for me to
play around with concurrency in Ruby. 

This gem is in early development. As such I would advise against using it in any 
environment where data integrity is important. I will release version 1.0 when 
I feel confident that the code is sufficiently robust.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pg_conduit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pg_conduit

## Quick Start

### `PgConduit.db_to_db(source, destination)`

Returns an instance of `PgConduit::Pipe` that will execute queries passed to
`read` and `write` against the `source` and `destination` databases, 
respectively.

The `source` and `destination` arguments are passed to 
[`PG::Connection`](https://www.rubydoc.info/gems/pg/PG/Connection), so any 
arguments that it accepts can be used.

#### Write one row at a time
    
```ruby
source      = 'postgres://user:pass@source/db'
destination = { dbname: 'my_local_db' }

pipe = PgConduit.db_to_db(source, destination)

pipe.read('SELECT id, full_name, email FROM users')
    .transform do |user|
      <<-SQL
        INSERT INTO customers(user_id, name, email)
        VALUES ('#{user['id']}', '#{user['full_name']}', '#{user['email']}')
      SQL
    end
    .exec
```

#### Write in batches

```ruby
source      = 'postgres://user:pass@source/db'
destination = { dbname: 'my_local_db' }

pipe = PgConduit.db_to_db(source, destination)

pipe.read('SELECT id, full_name, email FROM users')
    .transform do |user| 
      <<-SQL
        ('#{user['id']}', '#{user['full_name']}', '#{user['email']}')
      SQL
    end
    .write_batched(size: 100) do |values|
      <<-SQL
        INSERT INTO customers(user_id, name, email)
        VALUES #{values.join(',')}
      SQL
    end 
```

### `PgConduit.db_to_file(source, destination)`

Write output from source database to file.

```ruby
source      = 'postgres://user:pass@source/db'
destination = '/some/system/path/user_count.txt'

pipe = PgConduit.db_to_file(source, destination)

pipe.read('SELECT count(*) FROM users')
    .transform { |res| "Number of users: #{res['count']}" }
    .exec
```

### `PgConduit.db_to_stdout(source)`

Write output from source database to stdout.

```ruby
pipe = PgConduit.db_to_stdout('postgres://user:pass@source/db')

query = <<-SQL
  SELECT posts.user_id, users.email, count(posts.*) FROM users
  JOIN posts ON posts.user_id = users.id
  GROUP BY posts.user_id, users.email
SQL

pipe.read(query)
    .transform do |post_count| 
      "#{post_count['user_id']} | #{post_count['email']} - #{post_count['count']}"
    end
    .exec
```
        
### `PgConduit.db_to_null(source)`

Swallow output from source database. Mostly useful for testing. `exec` is an
alias of `write`.

```ruby
pipe = PgConduit.db_to_null('postgres://user:pass@source/db')
pipe.read('SELECT count(*) FROM users')
    .peak { |res| raise 'fail' unless res['count'] == 10 }
    .exec
```

## Development

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/pg_conduit.
