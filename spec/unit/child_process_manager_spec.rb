require_relative '../spec_helper'

require 'child_process_manager'

describe ChildProcessManager do
  before do
    ChildProcessManager.instance_eval { @managed_processes = [] }
  end

  describe '.add' do
    it 'adds a new process with the passed in options to CPM.managed_processes' do
      ChildProcessManager.add(host: '127.0.0.1', port: 7747)
      ChildProcessManager.managed_processes.should have(1).process
    end

    it 'doesnt add the same processes twice, and returns nil if it doesnt' do
      ChildProcessManager.managed_processes.should have(0).processes

      ChildProcessManager.add(host: '127.0.0.1', port: 7747).should_not be_nil
      ChildProcessManager.add(host: '127.0.0.1', port: 7747).should     be_nil

      ChildProcessManager.managed_processes.should have(1).process
    end

    it 'keeps the managed processes in the order they were initially added' do
      redis       = ChildProcessManager.add(tag: :redis,       port: 6379)
      redis_proxy = ChildProcessManager.add(tag: :redis_proxy, port: 6380)

      ChildProcessManager.managed_processes.should eq [redis, redis_proxy]
    end
  end

  describe 'reap_one' do
    it 'finds the process with the given port and sends it stop' do
      port_6379 = ChildProcessManager.add(host: '127.0.0.1', port: 6379)
      port_6379.expects(:stop)

      ChildProcessManager.reap_one(6379)
    end
  end

  describe 'reap_all' do
    it 'sends stop to all child processes' do
      one = ChildProcessManager.add(host: '127.0.0.1', port: 7747)
      two = ChildProcessManager.add(host: '127.0.0.1', port: 5525)

      one.expects(:stop)
      two.expects(:stop)

      ChildProcessManager.reap_all
    end
  end

  describe 'load_config_file' do
    it 'simply calls Kernel.load with the file' do
      Kernel.expects(:load).with('/this/file')

      ChildProcessManager.load_config('/this/file')
    end
  end

  describe '.start' do
    it 'sends start to all child processes' do
      one = ChildProcessManager.add(host: '127.0.0.1', port: 7747)
      two = ChildProcessManager.add(host: '127.0.0.1', port: 5525)

      one.expects(:start)
      two.expects(:start)

      ChildProcessManager.start
    end
  end
end

