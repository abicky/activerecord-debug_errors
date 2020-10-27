# frozen_string_literal: true

module ActiveRecord
  module DebugErrors
    module DisplayConnectionOwners
      def acquire_connection(*args)
        super
      rescue ActiveRecord::ConnectionTimeoutError
        dump_threads if ActiveRecord::Base.logger
        raise
      end

      private

      def dump_threads
        logger = ActiveRecord::Base.logger

        logger.error "ActiveRecord::ConnectionTimeoutError occured:"

        dump_thread = ->(thread) {
          logger.error "    Thread #{thread} status=#{thread.status} priority=#{thread.priority}"
          thread.backtrace&.each do |bt|
            logger.error "        #{bt}"
          end
        }

        owners = ActiveRecord::Base.connection_pool.connections.map(&:owner)
        logger.error "  connection owners:"
        owners.each(&dump_thread)

        other_threads = Thread.list - owners
        unless other_threads.empty?
          logger.error "  other threads:"
          other_threads.each(&dump_thread)
        end
      end
    end
  end
end


require "active_record/connection_adapters/abstract/connection_pool"
class ActiveRecord::ConnectionAdapters::ConnectionPool
  prepend ActiveRecord::DebugErrors::DisplayConnectionOwners
end
