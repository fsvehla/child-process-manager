require 'socket'
require 'timeout'

class ChildProcess
  ##
  # TERMs a process. If it is still up after +timeout+, KILLs it.
  def self.term_or_kill(pid, timeout)
    Process.kill('TERM', pid)

    term_sent_at = Time.now

    loop do
      begin
        if Time.now > term_sent_at + timeout
          Process.kill('KILL', pid)
          return
        end

        Process.kill(0, pid)
        sleep 0.1
      rescue Errno::ESRCH
        return
      end
    end
  end

  class TimeoutError < StandardError
    def initialize(child_process)
      @child_process = child_process
    end

    def message
      "#{ @child_process.cmd } did time out while waiting for port #{ @child_process.port }"
    end
  end

  attr_reader :cmd, :port, :on_connect, :on_stdout, :on_stderr, :connected, :kill_timeout

  def initialize(opts = {})
    @cmd        = opts[:cmd]
    @ip         = opts[:ip] || '127.0.0.1'
    @port       = opts[:port]
    @on_connect = opts[:on_connect]
    @io_stdout  = opts[:io_stdout]
    @io_stderr  = opts[:io_stderr]
    @pid        = nil

    @connect_timeout = opts[:kill_timeout] || 5
    @kill_timeout    = opts[:kill_timeout] || 2
    @pidfile         = opts[:pidfile]
    @before_start    = opts[:before_start]
  end

  def start
    return if listening?

    @before_start && @before_start.call

    o = {:out => '/dev/null', :err => '/dev/null'}
    o[:out] = @io_stdout if @io_stdout
    o[:err] = @io_stderr if @io_stderr

    @pid = Process.spawn(@cmd, o)
    @spawned_at = Time.now

    loop do
      if listening?
        @on_connect && @on_connect.call
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
      ChildProcess.term_or_kill(@pid, @kill_timeout)
    end

    if @pidfile && File.file?(@pidfile)
      pidfile_pid = Integer(File.read(@pidfile).chomp)

      ChildProcess.term_or_kill(pidfile_pid, @kill_timeout)
    end
  end
end

class ChildProcessManager

  def self.init
    @@managed_processes ||= {}
  end

  def self.spawn(processes)
    self.init

    if processes.is_a?(Hash)
      processes = [processes]
    end

    processes.each do |process_options|
      process_options[:ip] ||= '127.0.0.1'
      mpskey = "#{process_options[:ip]}:#{process_options[:port]}"

      if !@@managed_processes[mpskey]
        cp = ChildProcess.new(process_options)
        cp.start
        @@managed_processes[mpskey] = cp
      end
    end
  end

  def self.reap_all
    self.init

    @@managed_processes.each do |address,child_process|
      child_process.stop if child_process
      @@managed_processes.delete(address)
    end
  end

  def self.managed_processes
    @@managed_processes
  end

  def self.reap_one(*args)
    self.init
    port = 0; ip = '127.0.0.1'

    if args.size == 1
      port = args[0]
    elsif args.size == 2
      ip = args[0]
      port = args[1]
    end
    address = "#{ip}:#{port}"
    if @@managed_processes[address]
      @@managed_processes[address].stop
      @@managed_processes.delete(address)
    end
  end
end
