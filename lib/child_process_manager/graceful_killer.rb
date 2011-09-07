module ChildProcessManager
  class GracefulKiller
    def self.kill(pid, timeout, default_signal = 'TERM')
      last_signal  = default_signal
      term_sent_at = Time.now

      Process.kill(default_signal, pid) rescue nil

      loop do
        if Time.now > term_sent_at + timeout
          last_signal = 'KILL'
          Process.kill('KILL', pid)
        end

        Process.kill(0, pid)
        sleep 0.1
      end
    rescue Errno::ESRCH
      return last_signal
    end
  end
end

