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
    it "displays connection owners" do
      expect {
        Array.new(ActiveRecord::Base.connection_pool.size + 1) do
          Thread.new do
            ActiveRecord::Base.connection_pool.checkout(0.1)
          end
        end.each(&:join)
      }.to raise_error(ActiveRecord::ConnectionTimeoutError)

      expect(log.string).to include("ActiveRecord::ConnectionTimeoutError occured")
    end
  end
end
