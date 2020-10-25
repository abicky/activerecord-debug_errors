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

  describe "#execute" do
    context "when ActiveRecord::Deadlocked occurs" do
      it "displays latest detected deadlock" do
        ths = []
        ths << Thread.new do
          User.transaction do
            User.lock.find_by!(name: 'foo')
            sleep 0.1
            User.lock.find_by!(name: 'bar')
          end
        end

        ths << Thread.new do
          User.transaction do
            User.lock.find_by!(name: 'bar')
            sleep 0.1
            User.lock.find_by!(name: 'foo')
          end
        end

        expect {
          ths.each(&:join)
        }.to raise_error(ActiveRecord::Deadlocked)
        expect(log.string).to include("LATEST DETECTED DEADLOCK")
        expect(log.string).to include("WE ROLL BACK TRANSACTION")
      end
    end

    context "when ActiveRecord::LockWaitTimeout occurs" do
      it "displays transactions and processlist" do
        ths = []
        ths << Thread.new do
          User.transaction do
            User.lock.find_by!(name: 'foo')
            sleep 2
          end
        end

        ths << Thread.new do
          User.transaction do
            User.lock.find_by!(name: 'foo')
            sleep 2
          end
        end

        expect {
          ths.each(&:join)
        }.to raise_error(ActiveRecord::LockWaitTimeout)

        expect(log.string).to include("TRANSACTIONS")
        expect(log.string).to include("---TRANSACTION")
        expect(log.string).to include("SHOW FULL PROCESSLIST")
      end
    end
  end
end
