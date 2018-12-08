
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

# We store the starting unixtime

RUNNER_KV_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Runner"

class NSXRunner

    # NSXRunner::isRunning?(id): Boolean
    def self.isRunning?(id)
        status = KeyValueStore::getOrNull(RUNNER_KV_REPOSITORY_FOLDERPATH, "e22b0997-557c-4bc0-a265-13d6a7a62b3f:#{id}")
        !status.nil?
    end

    # NSXRunner::start(id): Boolean
    def self.start(id)
        return false if NSXRunner::isRunning?(id)
        KeyValueStore::set(RUNNER_KV_REPOSITORY_FOLDERPATH, "e22b0997-557c-4bc0-a265-13d6a7a62b3f:#{id}", Time.new.to_f) 
        true
    end

    # NSXRunner::stop(id): Null or Float
    def self.stop(id)
        unixtime = KeyValueStore::getOrNull(RUNNER_KV_REPOSITORY_FOLDERPATH, "e22b0997-557c-4bc0-a265-13d6a7a62b3f:#{id}")
        if unixtime then
            KeyValueStore::destroy(RUNNER_KV_REPOSITORY_FOLDERPATH, "e22b0997-557c-4bc0-a265-13d6a7a62b3f:#{id}")
            unixtime.to_f
        else
            nil
        end
    end

    # NSXRunner::runningTimeOrNull(id) Null or Float
    def self.runningTimeOrNull(id)
        unixtime = KeyValueStore::getOrNull(RUNNER_KV_REPOSITORY_FOLDERPATH, "e22b0997-557c-4bc0-a265-13d6a7a62b3f:#{id}")
        if unixtime then
            unixtime.to_f
        else
            nil
        end
    end

end


