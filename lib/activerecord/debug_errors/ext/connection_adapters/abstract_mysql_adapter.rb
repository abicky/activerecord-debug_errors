# frozen_string_literal: true
require "active_record/connection_adapters/abstract_mysql_adapter"

module ActiveRecord
  module DebugErrors
    module DisplayMySQLInformation
      private

      # Override `ActiveRecord::ConnectionAdapters::AbstractAdapter#translate_exception_class`
      # so that it obtains an error happened on query executions.
      def translate_exception_class(*args, **kwargs)
        if  args[0].is_a?(ActiveRecord::Deadlocked)
          if logger
            logger.error "ActiveRecord::Deadlocked occurred:"
            display_latest_detected_deadlock
          end
        elsif args[0].is_a?(ActiveRecord::LockWaitTimeout)
          if logger
            logger.error "ActiveRecord::LockWaitTimeout occurred:"
            display_transactions
            display_processlist
          end
        end
        super(*args, **kwargs)
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
