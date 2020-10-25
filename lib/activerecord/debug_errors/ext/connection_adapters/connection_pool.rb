# frozen_string_literal: true

module ActiveRecord
  module DebugErrors
    module DisplayConnectionOwners
      def acquire_connection(*args)
        super
      rescue ActiveRecord::ConnectionTimeoutError
        display_connection_owners if ActiveRecord::Base.logger
        raise
      end

      private

      def display_connection_owners
        logger = ActiveRecord::Base.logger

        logger.error "ActiveRecord::ConnectionTimeoutError occured:"
        ActiveRecord::Base.connection_pool.connections.map(&:owner).each do |thread|
          logger.error "  Thread #{thread} status=#{thread.status} priority=#{thread.priority}"
          thread.backtrace&.each do |bt|
            logger.error "      #{bt}"
          end
        end
      end
    end
  end
end


require "active_record/connection_adapters/abstract/connection_pool"
class ActiveRecord::ConnectionAdapters::ConnectionPool
  prepend ActiveRecord::DebugErrors::DisplayConnectionOwners
end
