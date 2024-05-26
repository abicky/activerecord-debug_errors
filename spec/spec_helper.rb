require "bundler/setup"
require "activerecord/debug_errors"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    base_db_config = {
      adapter: "mysql2",
      host:     ENV['MYSQL_HOST'],
      port:     ENV['MYSQL_PORT'],
      username: ENV['MYSQL_USERNAME'],
      password: ENV['MYSQL_PASSWORD'],
      database: ENV['MYSQL_DATABASE'],
      variables: {
        innodb_lock_wait_timeout: 1,
      },
    }

    user_for_replica = 'activerecord-debug_errors'
    # For compatibility. Rails deprecated since 6.1 and removed this option since 7.1.
    # https://github.com/rails/rails/pull/44827/commits/ad52c0a19714a1b87a7d0c626a8b364cf95414cf
    if ActiveRecord::Base.respond_to?(:legacy_connection_handling)
      ActiveRecord::Base.legacy_connection_handling = false
    end
    ActiveRecord::Base.configurations = {
      default_env: {
        primary: base_db_config,
        primary_replica: base_db_config.merge(username: user_for_replica, replica: true),
      }
    }

    ActiveRecord::Base.establish_connection(:default_env)

    unless ActiveRecord::Base.connection.table_exists?('users')
      ActiveRecord::Base.connection.create_table('users') do |t|
        t.string 'name'
        t.index ['name'], name: 'ux_name', unique: true
      end
    end

    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
      connects_to database: { writing: :primary, reading: :primary_replica }
    end
    class User < ApplicationRecord; end

    User.find_or_create_by!(name: 'foo')
    User.find_or_create_by!(name: 'bar')

    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE USER IF NOT EXISTS '#{user_for_replica}'@'%' IDENTIFIED BY '#{ENV['MYSQL_PASSWORD']}'
    SQL
    ActiveRecord::Base.connection.execute(<<~SQL)
      GRANT SELECT, LOCK TABLES ON *.* To '#{user_for_replica}'@'%'
    SQL
  end
end
