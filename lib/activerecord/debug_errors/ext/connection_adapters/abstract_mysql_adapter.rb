# frozen_string_literal: true
require "active_record/connection_adapters/abstract_mysql_adapter"

module ActiveRecord
  module DebugErrors
    module DisplayMySQLInformation
      # For Rails 6.0 or 6.1. Rails 7 or later never calls ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter#execute
      # cf. https://github.com/rails/rails/pull/43097
      if ActiveRecord.version < Gem::Version.new("7.0.0")
        def execute(*args, **kwargs)
          super(*args, **kwargs)
        rescue ActiveRecord::Deadlocked
          handle_deadlocked
          raise
        rescue ActiveRecord::LockWaitTimeout
          handle_lock_wait_timeout
          raise
        end
      end

      private

      # For Rails 7.0 or later. Override `ActiveRecord::ConnectionAdapters::AbstractAdapter#translate_exception_class`
      # so that it obtains an error happened on query executions.
      def translate_exception_class(*args, **kwargs)
        if  args[0].is_a?(ActiveRecord::Deadlocked)
          handle_deadlocked
        elsif args[0].is_a?(ActiveRecord::LockWaitTimeout)
          handle_lock_wait_timeout
        end
        super(*args, **kwargs)
      end

      def handle_deadlocked
        if logger
          logger.error "ActiveRecord::Deadlocked occurred:"
          display_latest_detected_deadlock
        end
      end

      def handle_lock_wait_timeout
        if logger
          logger.error "ActiveRecord::LockWaitTimeout occurred:"
          display_transactions
          display_processlist
        end
      end

      def display_latest_detected_deadlock
        display_innodb_status_section("LATEST DETECTED DEADLOCK")
      end

      def display_transactions
        display_innodb_status_section("TRANSACTIONS")
      end

      def display_processlist
        logger.error "-----------"
        logger.error "PROCESSLIST"
        logger.error "-----------"
        ActiveRecord::Base.connection.execute("SHOW FULL PROCESSLIST").each do |row|
          logger.error row.join("\t")
        end
      end

      def display_innodb_status_section(section_name)
        sql = "SHOW ENGINE INNODB STATUS"
        status = nil
        begin
          status = ActiveRecord::Base.connection.execute(sql).first[2]
        rescue ActiveRecord::StatementInvalid => e
          logger.error "Failed to execute '#{sql}': #{e.message}"
          return
        end

        prev_line = nil
        in_deadlock_section = false
        status.each_line do |line|
          line.chomp!

          if line == section_name
            logger.error prev_line
            in_deadlock_section = true
          end

          if in_deadlock_section
            break if prev_line != section_name && line.match?(/\A-+\z/)
            logger.error line
          end

          prev_line = line
        end
      end
    end
  end
end

class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  prepend ActiveRecord::DebugErrors::DisplayMySQLInformation
end
