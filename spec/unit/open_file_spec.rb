require_relative '../spec_helper'

require 'child_process_manager'

describe ChildProcessManager::OS::OpenFile do
  describe 'LSOF output parsing' do
    it 'extracts the line correctly' do
             # COMMAND     PID      USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
      line = 'ruby      61753 Ferdinand    8u  IPv4 0xffffff8027450500      0t0  TCP *:27017 (LISTEN)'

      open_file = ChildProcessManager::OS::OpenFile.parse_lsof_line(line)

      open_file.command.should eq 'ruby'
      open_file.pid.should     eq 61753
      open_file.user.should    eq 'Ferdinand'
      open_file.fd.should      eq '8u'
      open_file.type.should    eq 'IPv4'
      open_file.device.should  eq '0xffffff8027450500'
      open_file.size.should    eq '0t0'
      open_file.node.should    eq 'TCP'
      open_file.name.should    eq '*:27017 (LISTEN)'
    end
  end

  describe '#listens_on?' do
    include ChildProcessManager::OS

    it 'returns true if port and host match' do
      OpenFile.new(name: '127.0.0.1:7707').listens_on?(7707).should be
      OpenFile.new(name: '127.0.0.1:7707').listens_on?(7707, '127.0.0.1').should be

      OpenFile.new(name: '127.0.0.1:7707').listens_on?(7708).should_not be
      OpenFile.new(name: '127.0.0.1:7707').listens_on?(7707, '10.0.0.1').should_not be
    end

    it 'returns true if the host listens on all interfaces' do
      OpenFile.new(name: '*:7707').listens_on?(7707).should be
      OpenFile.new(name: '*:7707').listens_on?(7707, '127.0.0.1').should be
      OpenFile.new(name: '*:7707').listens_on?(7707, '10.0.0.1').should be

      OpenFile.new(name: '*:7707').listens_on?(7708).should_not be
    end
  end
end

