#require 'child-process-manager/child_process'

module ChildProcessManager
  autoload :ChildProcess,   'child_process_manager/child_process'
  autoload :GracefulKiller, 'child_process_manager/graceful_killer'

  class << self
    def managed_processes
      @managed_processes ||= []
    end
  end

  def self.load_config(path)
    Kernel.load(path)
  end

  # Returns an array of spawned processes. Processes that were already spawned,
  # aren't returned.
  def self.add(process_options)
    child_process = ChildProcess.new(process_options)

    unless managed_processes.any? { |p| p.hash == child_process.hash }
      managed_processes << child_process
      child_process
    end
  end

  def self.start
    managed_processes.each { |p| p.start }
  end

  def self.spawn(process_options)
    if process = self.add(process_options)
      process.start
    end
  end

  def self.reap_all
    managed_processes.each do |process|
      process.stop
    end
  end

  def self.reap_one(*args)
    port = 0
    ip   = '127.0.0.1'

    if args.size == 1
      port = args[0]
    elsif args.size == 2
      ip  = args[0]
      port = args[1]
    end

    if process = managed_processes.find { |p| p.port == port && p.ip == ip }
      process.stop
    end
  end
end
