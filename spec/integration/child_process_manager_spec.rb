$LOAD_PATH << File.expand_path('../../../lib', __FILE__)

require "rspec"
require "child-process-manager"

describe "Child Process Manager" do

  it "spawns processes" do
    ChildProcessManager.spawn(
        :port=> 11212,
        :cmd=>  'memcached -p 11212 -l 127.0.0.1'
      )

  end
  it "kills processes" do
    ChildProcessManager.spawn(
        :port=> 11212,
        :cmd=>  'memcached -p 11212 -l 127.0.0.1'
      )

      ChildProcessManager.reap_all

  end
end