module ChildProcessManager
  class GracefulKiller
    def self.kill(pid, timeout)
      last_signal = 'TERM'

      term_sent_at = Time.now
      Process.kill('TERM', pid)

      loop {
        if Time.now > term_sent_at + timeout
          last_signal = 'KILL'
          ::Process.kill('KILL', pid)
        end

        Process.kill(0, pid)
        sleep 0.1
      }
    rescue Errno::ESRCH
      return last_signal
    end
  end
end

