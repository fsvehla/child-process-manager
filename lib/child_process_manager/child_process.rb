require 'socket'
require 'timeout'

module ChildProcessManager
  class ChildProcess
    class TimeoutError < StandardError
      def initialize(child_process)
        @child_process = child_process
      end

      def message
        "#{ @child_process.cmd } did time out while waiting for port #{ @child_process.port }"
      end
    end

    attr_reader :cmd, :port, :on_ready, :on_stdout, :on_stderr, :connected, :kill_timeout, :tag, :ip

    def initialize(opts = {})
      @cmd        = opts[:cmd]
      @ip         = opts[:ip] || '127.0.0.1'
      @port       = opts[:port]
      @on_ready   = opts[:on_ready] || opts[:on_connect]
      @io_stdout  = opts[:io_stdout]
      @io_stderr  = opts[:io_stderr]
      @pid        = nil
      @tag        = opts[:tag] || opts[:cmd]

      @connect_timeout = opts[:kill_timeout] || 5
      @kill_timeout    = opts[:kill_timeout] || 2
      @pidfile         = opts[:pidfile]
      @before_start    = opts[:before_start]
    end

    def debug(line)
      now   = Time.now
      STDERR.puts "\033[32m[CPM]\033[0m #{ now.strftime('%H:%M:%S') }.#{ '%03d' % (now.usec / 1000) } -- #{ line }"
    end

    def hash
      "#{ @ip }:#{ @port }".hash
    end

    def start
      if listening?
        debug "#{ @tag } was already up"

        @on_ready && @on_ready.call
        return
      else
        debug "#{ @tag } isn't listening on #{ @port }. Spawning"
      end

      @before_start && @before_start.call

      o = {:out => '/dev/null', :err => '/dev/null'}
      o[:out] = @io_stdout if @io_stdout
      o[:err] = @io_stderr if @io_stderr

      @pid = Process.spawn(@cmd, o)
      @spawned_at = Time.now

      loop do
        if listening?
          @on_ready && @on_ready.call
          return
        end

        if Time.now > @spawned_at + @connect_timeout
          raise TimeoutError.new(self)
        end

        sleep 0.2
      end
    end

    def listening?
      Timeout.timeout(1) do
        s = TCPSocket.open(@ip, @port)
        s.close
      end

      return true
    rescue Timeout::Error
      return false
    rescue Errno::ECONNREFUSED
      return false
    end

    def stop
      if @pid
        Process.detach(@pid)

        debug "Gracefully killing our spawned child process #{ @tag } with PID #{ @pid }..."

        signal = ChildProcessManager::GracefulKiller.kill(@pid,  @kill_timeout)
        debug "Stopped #{ @tag } with SIG#{ signal }"
      elsif @pidfile && File.file?(@pidfile)
        pidfile_pid = Integer(File.read(@pidfile).chomp)

        debug "Gracefully killing process #{ @tag } with PID #{ pidfile_pid } from #{ @pidfile }..."

        signal = ChildProcessManager::GracefulKiller.kill(pidfile_pid,  @kill_timeout)
        debug "Stopped #{ @tag } with SIG#{ signal }"
      end
    end
  end
end
