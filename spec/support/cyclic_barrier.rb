# This class is a simple implementation of CyclicBarrier in Java
class CyclicBarrier
  def initialize(parties)
    @cv = ConditionVariable.new
    @mutex = Mutex.new
    @parties = parties
    @number_waiting = 0
  end

  def await(timeout = nil)
    @mutex.synchronize do
      @number_waiting += 1
      if @number_waiting == @parties
        @cv.broadcast
      else
        @cv.wait(@mutex, timeout)
        raise Timeout::Error if @number_waiting != @parties
      end
    end
  end
end
