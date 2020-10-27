# ActiveRecord::DebugErrors

![](https://github.com/abicky/activerecord-debug_errors/workflows/CI/badge.svg?branch=master)

ActiveRecord::DebugErrors is an extension of activerecord to display useful debug logs on errors.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-debug_errors'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install activerecord-debug_errors

## Usage

You only have to load the gem:

```ruby
require 'activerecord-debug_errors'
```

By loading the gem, you can see useful debug logs on errors as described below.

### ActiveRecord::LockWaitTimeout

If you use MySQL and when `ActiveRecord::LockWaitTimeout` occurs, you can see a log like below:

```
ActiveRecord::LockWaitTimeout occurred:
------------
TRANSACTIONS
------------
Trx id counter 1511885
Purge done for trx's n:o < 1511588 undo n:o < 0 state: running but idle
History list length 42
LIST OF TRANSACTIONS FOR EACH SESSION:
---TRANSACTION 421781578720592, not started
0 lock struct(s), heap size 1136, 0 row lock(s)
---TRANSACTION 421781578719688, not started
0 lock struct(s), heap size 1136, 0 row lock(s)
---TRANSACTION 421781578718784, not started
0 lock struct(s), heap size 1136, 0 row lock(s)
---TRANSACTION 421781578716976, not started
0 lock struct(s), heap size 1136, 0 row lock(s)
---TRANSACTION 421781578717880, not started
0 lock struct(s), heap size 1136, 0 row lock(s)
---TRANSACTION 1511884, ACTIVE 2 sec
1 lock struct(s), heap size 1136, 1 row lock(s)
MySQL thread id 970, OS thread handle 123145454895104, query id 62140 localhost 127.0.0.1 root starting
SHOW ENGINE INNODB STATUS
---TRANSACTION 1511883, ACTIVE 2 sec
3 lock struct(s), heap size 1136, 2 row lock(s)
MySQL thread id 969, OS thread handle 123145455452160, query id 62138 localhost 127.0.0.1 root
-----------
PROCESSLIST
-----------
695     root    localhost:60956 information_schema      Sleep   3
853     root    localhost:60036         Sleep   23
966     root    localhost:54726 test    Sleep   2
967     root    localhost:54731 test    Sleep   2
968     root    localhost:54732 test    Sleep   2
969     root    localhost:54734 test    Sleep   2
970     root    localhost:54735 test    Query   0       starting        SHOW FULL PROCESSLIST
```

In the preceding log, you can find that there were two long transactions. The first one was created by thread id 969 (the client localhost:54734), and the second one was created by thread id 970 (the client localhost:54735).


### ActiveRecord::Deadlocked

If you use MySQL and when `ActiveRecord::Deadlocked` occurs, you can see the information of the latest detected deadlock:

```
ActiveRecord::Deadlocked occurred:
------------------------
LATEST DETECTED DEADLOCK
------------------------
2020-10-26 05:16:54 0x700008fec000
*** (1) TRANSACTION:
TRANSACTION 1511857, ACTIVE 0 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 4 lock struct(s), heap size 1136, 3 row lock(s)
MySQL thread id 919, OS thread handle 123145453502464, query id 61760 localhost 127.0.0.1 root statistics
SELECT `users`.* FROM `users` WHERE `users`.`name` = 'bar' LIMIT 1 FOR UPDATE
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 6659 page no 4 n bits 72 index ux_name of table `test`.`users` trx id 1511857 lock_mode X locks rec but not gap waiting
Record lock, heap no 3 PHYSICAL RECORD: n_fields 2; compact format; info bits 0
 0: len 3; hex 626172; asc bar;;
 1: len 8; hex 8000000000000002; asc         ;;

*** (2) TRANSACTION:
TRANSACTION 1511858, ACTIVE 0 sec starting index read
mysql tables in use 1, locked 1
4 lock struct(s), heap size 1136, 3 row lock(s)
MySQL thread id 920, OS thread handle 123145453223936, query id 61761 localhost 127.0.0.1 root statistics
SELECT `users`.* FROM `users` WHERE `users`.`name` = 'foo' LIMIT 1 FOR UPDATE
*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 6659 page no 4 n bits 72 index ux_name of table `test`.`users` trx id 1511858 lock_mode X locks rec but not gap
Record lock, heap no 3 PHYSICAL RECORD: n_fields 2; compact format; info bits 0
 0: len 3; hex 626172; asc bar;;
 1: len 8; hex 8000000000000002; asc         ;;

*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 6659 page no 4 n bits 72 index ux_name of table `test`.`users` trx id 1511858 lock_mode X locks rec but not gap waiting
Record lock, heap no 2 PHYSICAL RECORD: n_fields 2; compact format; info bits 0
 0: len 3; hex 666f6f; asc foo;;
 1: len 8; hex 8000000000000001; asc         ;;

*** WE ROLL BACK TRANSACTION (2)
```

### ActiveRecord::ConnectionTimeoutError

When `ActiveRecord::ConnectionTimeoutError` occurs, you can see the information of connection owners (threads):

```
ActiveRecord::ConnectionTimeoutError occured:
  connection owners:
    Thread #<Thread:0x00007fbda205fa70 sleep_forever> status=sleep priority=0
        /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:32:in `join'
        /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:32:in `each'
        /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:32:in `block (4 levels) in <top (required)>'
        /path/to/ruby/gems/2.7.0/gems/rspec-expectations-3.9.3/lib/rspec/matchers/built_in/raise_error.rb:52:in `matches?'
        /path/to/ruby/gems/2.7.0/gems/rspec-expectations-3.9.3/lib/rspec/expectations/handler.rb:50:in `block in handle_matcher'
        /path/to/ruby/gems/2.7.0/gems/rspec-expectations-3.9.3/lib/rspec/expectations/handler.rb:27:in `with_matcher'
        /path/to/ruby/gems/2.7.0/gems/rspec-expectations-3.9.3/lib/rspec/expectations/handler.rb:48:in `handle_matcher'
        /path/to/ruby/gems/2.7.0/gems/rspec-expectations-3.9.3/lib/rspec/expectations/expectation_target.rb:65:in `to'
        /path/to/ruby/gems/2.7.0/gems/rspec-expectations-3.9.3/lib/rspec/expectations/expectation_target.rb:101:in `to'
        /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:26:in `block (3 levels) in <top (required)>'
-- snip --
        /path/to/bin/rspec:23:in `load'
        /path/to/bin/rspec:23:in `<main>'
    Thread #<Thread:0x00007fbda4908008 /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:29 dead> status=false priority=0
    Thread #<Thread:0x00007fbda4909688 /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:29 dead> status=false priority=0
    Thread #<Thread:0x00007fbda4908170 /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:29 dead> status=false priority=0
    Thread #<Thread:0x00007fbda48fbd58 /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:29 dead> status=false priority=0
  other threads:
    Thread #<Thread:0x00007fbda52b3ad0 /path/to/ruby/gems/2.7.0/gems/activerecord-6.0.3.4/lib/active_record/connection_adapters/abstract/connection_pool.rb:334 sleep> status=sleep priority=0
        /path/to/ruby/gems/2.7.0/gems/activerecord-6.0.3.4/lib/active_record/connection_adapters/abstract/connection_pool.rb:337:in `sleep'
        /path/to/ruby/gems/2.7.0/gems/activerecord-6.0.3.4/lib/active_record/connection_adapters/abstract/connection_pool.rb:337:in `block in spawn_thread'
    Thread #<Thread:0x00007fbda5100170 /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:24 sleep> status=sleep priority=0
        /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:24:in `sleep'
        /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:24:in `block (4 levels) in <top (required)>'
    Thread #<Thread:0x00007fbda48fbc40 /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:29 run> status=run priority=0
        /path/to/activerecord-debug_errors/lib/activerecord/debug_errors/ext/connection_adapters/connection_pool.rb:22:in `backtrace'
        /path/to/activerecord-debug_errors/lib/activerecord/debug_errors/ext/connection_adapters/connection_pool.rb:22:in `block in dump_threads'
        /path/to/activerecord-debug_errors/lib/activerecord/debug_errors/ext/connection_adapters/connection_pool.rb:34:in `each'
        /path/to/activerecord-debug_errors/lib/activerecord/debug_errors/ext/connection_adapters/connection_pool.rb:34:in `dump_threads'
        /path/to/activerecord-debug_errors/lib/activerecord/debug_errors/ext/connection_adapters/connection_pool.rb:9:in `rescue in acquire_connection'
        /path/to/activerecord-debug_errors/lib/activerecord/debug_errors/ext/connection_adapters/connection_pool.rb:6:in `acquire_connection'
        /path/to/ruby/gems/2.7.0/gems/activerecord-6.0.3.4/lib/active_record/connection_adapters/abstract/connection_pool.rb:593:in `checkout'
        /path/to/activerecord-debug_errors/spec/activerecord/debug_errors/ext/connection_adapters/connection_pool_spec.rb:30:in `block (6 levels) in <top (required)>'
```

In the preceding log, you can find that there were five connection owners and three other threads. The first owner was the main thread (Thread:0x00007fbda205fa70) and the other owners are dead threads.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abicky/activerecord-debug_errors.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
