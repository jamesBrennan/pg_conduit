# PgConduit

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
    
    source      = 'postgres://user:pass@source/db'
    destination = { dbname: 'my_local_db' }
    
    pipe = PgConduit.db_to_db(source, destination)
    
    pipe.read('SELECT id, full_name, email FROM users')
        .write do |user|
          <<-SQL
            INSERT INTO customers(user_id, name, email)
            VALUES ('#{user['id']}', '#{user['full_name']}', '#{user['email']}')
          SQL
        end 

#### Write in batches

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


## Development

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/pg_conduit.
