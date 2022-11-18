# encoding: UTF-8

class Git

    # Git::remoteHash()
    def self.remoteHash()
        `git ls-remote https://github.com/shtukas/stargate.git HEAD`.strip[0, 10]
    end

    # Git::localHash()
    def self.localHash()
        `cd '#{File.dirname(__FILE__)}/..' ; git log -1 | grep ^commit | cut -d " " -f 2`.strip[0, 10]
    end

    # Git::updateFromRemote()
    def self.updateFromRemote()
        system("cd '#{File.dirname(__FILE__)}/..' ; git pull ")
    end

    # Git::updateFromRemoteIfNeeded()
    def self.updateFromRemoteIfNeeded()
        remoteHash = Git::localHash()
        return if remoteHash == ""
        if remoteHash != Git::localHash() then
            Git::updateFromRemote()
        end
    end
end
