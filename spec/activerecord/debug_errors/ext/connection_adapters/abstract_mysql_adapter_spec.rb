require "spec_helper"
require "support/cyclic_barrier"

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
      def cause_deadlock(role:)
        barrier = CyclicBarrier.new(2)

        ths = []
        ths << Thread.new do
          ActiveRecord::Base.connected_to(role: role) do
            User.transaction do
              User.lock.find_by!(name: 'foo')
              barrier.await(1)
              User.lock.find_by!(name: 'bar')
            end
          end
        end

        ths << Thread.new do
          ActiveRecord::Base.connected_to(role: role) do
            User.transaction do
              User.lock.find_by!(name: 'bar')
              barrier.await(1)
              User.lock.find_by!(name: 'foo')
            end
          end
        end

        ths.each(&:join)
      end

      context "when the user has the permission to execute 'SHOW ENGINE INNODB STATUS'" do
        it "displays latest detected deadlock" do
          expect {
            cause_deadlock(role: :writing)
          }.to raise_error(ActiveRecord::Deadlocked)
          expect(log.string).to include("LATEST DETECTED DEADLOCK")
          expect(log.string).to include("WE ROLL BACK TRANSACTION")
        end
      end

      context "when the user doesn't have the permission to execute 'SHOW ENGINE INNODB STATUS'" do
        it "displays an error message" do
          expect {
            ActiveRecord::Base.connected_to(role: :reading) do
              cause_deadlock(role: :reading)
            end
          }.to raise_error(ActiveRecord::Deadlocked)
          expect(log.string).to include("Failed to execute")
        end
      end
    end

    context "when ActiveRecord::LockWaitTimeout occurs" do
      it "displays transactions and processlist" do
        barrier = CyclicBarrier.new(2)

        ths = Array.new(2) do
          Thread.new do
            User.transaction do
              barrier.await(1)
              User.lock.find_by!(name: 'foo')
              sleep 2
            end
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
