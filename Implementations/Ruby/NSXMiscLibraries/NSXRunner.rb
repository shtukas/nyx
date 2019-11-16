
# encoding: UTF-8

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

# We store the starting unixtime

class NSXRunner

    # NSXRunner::isRunning?(id): Boolean
    def self.isRunning?(id)
        status = KeyValueStore::getOrNull(nil, "e22b0997-557c-4bc0-a265-13d6a7a62b3f:#{id}")
        !status.nil?
    end

    # NSXRunner::start(id): Boolean
    def self.start(id)
        return false if NSXRunner::isRunning?(id)
        KeyValueStore::set(nil, "e22b0997-557c-4bc0-a265-13d6a7a62b3f:#{id}", Time.new.to_f) 
        true
    end

    # NSXRunner::stop(id): Null or Float
    def self.stop(id)
        unixtime = KeyValueStore::getOrNull(nil, "e22b0997-557c-4bc0-a265-13d6a7a62b3f:#{id}")
        if unixtime then
            KeyValueStore::destroy(nil, "e22b0997-557c-4bc0-a265-13d6a7a62b3f:#{id}")
            Time.new.to_f - unixtime.to_f
        else
            nil
        end
    end

    # NSXRunner::runningTimeOrNull(id) Null or Float
    def self.runningTimeOrNull(id)
        unixtime = KeyValueStore::getOrNull(nil, "e22b0997-557c-4bc0-a265-13d6a7a62b3f:#{id}")
        if unixtime then
            Time.new.to_f - unixtime.to_f
        else
            nil
        end
    end

end


