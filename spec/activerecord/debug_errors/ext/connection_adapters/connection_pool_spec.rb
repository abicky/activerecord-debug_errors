require "spec_helper"

RSpec.describe ActiveRecord::DebugErrors::DisplayConnectionOwners do
  let(:log) { StringIO.new }

  around do |example|
    report_on_exception = Thread.report_on_exception
    Thread.report_on_exception = false

    prev_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = Logger.new(log)

    example.run
  ensure
    ActiveRecord::Base.logger = prev_logger
    Thread.report_on_exception = report_on_exception
  end

  describe "#acquire_connection" do
    it "displays connection owners and other threads" do
      Thread.new { sleep 10 } # another thread

      mutex = Mutex.new
      cv = ConditionVariable.new

      expect {
        ActiveRecord::Base.connection # Ensure to acquire a connection
        Array.new(ActiveRecord::Base.connection_pool.size) do
          Thread.new do
            mutex.synchronize do
              ActiveRecord::Base.connection_pool.checkout(0.1)
              cv.wait(mutex, 1)
            rescue
              cv.broadcast
              raise
            end
          end
        end.each(&:join)
      }.to raise_error(ActiveRecord::ConnectionTimeoutError)

      expect(log.string).to include("ActiveRecord::ConnectionTimeoutError occurred:")
      expect(log.string).to include("connection owners:")
      expect(log.string).to include("other threads")

      threads = log.string.scan(/Thread:0x[0-9a-f]+/)
      expect(threads).to eq threads.uniq
    end
  end
end
