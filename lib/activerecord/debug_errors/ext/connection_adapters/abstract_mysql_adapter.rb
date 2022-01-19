# frozen_string_literal: true
require "active_record/connection_adapters/abstract_mysql_adapter"

module ActiveRecord
  module DebugErrors
    module DisplayMySQLInformation
      # Rails 7 or later never calls ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter#execute
      # cf. https://github.com/rails/rails/pull/43097
      if ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.private_method_defined?(:raw_execute)
        method_name = :raw_execute
      else
        method_name = :execute
      end
      define_method(method_name) do |*args, **kwargs|
        super(*args, **kwargs)
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
      private method_name if method_name == :raw_execute

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

class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  prepend ActiveRecord::DebugErrors::DisplayMySQLInformation
end
