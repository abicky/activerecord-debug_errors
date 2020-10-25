require "bundler/setup"
require "activerecord/debug_errors"

ActiveRecord::Base.establish_connection(
  adapter: "mysql2",
  host:     ENV['MYSQL_HOST'],
  port:     ENV['MYSQL_PORT'],
  username: ENV['MYSQL_USERNAME'],
  password: ENV['MYSQL_PASSWORD'],
  database: ENV['MYSQL_DATABASE'],
  variables: {
    innodb_lock_wait_timeout: 1,
  },
)

unless ActiveRecord::Base.connection.table_exists?('users')
  ActiveRecord::Base.connection.create_table('users') do |t|
    t.string 'name'
    t.index ['name'], name: 'ux_name', unique: true
  end
end

class User < ActiveRecord::Base; end

User.find_or_create_by!(name: 'foo')
User.find_or_create_by!(name: 'bar')

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
