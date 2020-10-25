# frozen_string_literal: true

module ActiveRecord
  module DebugErrors
    module DisplayMySQLInformation
      def execute(*args)
        super
      rescue ActiveRecord::Deadlocked
        if logger
          logger.error "ActiveRecord::Deadlocked occurred:"
          display_latest_detected_deadlock
        end
        raise
      rescue ActiveRecord::LockWaitTimeout
        if logger
          logger.error "ActiveRecord::LockWaitTimeout occurred:"
          display_transactions
          display_processlist
        end
        raise
      end

      private

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
        status = ActiveRecord::Base.connection.execute("SHOW ENGINE INNODB STATUS").first[2]

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

require "active_record/connection_adapters/abstract_mysql_adapter"
class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  prepend ActiveRecord::DebugErrors::DisplayMySQLInformation
end
