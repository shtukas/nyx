
# encoding: UTF-8

# require_relative "Runner.rb"
=begin 
    Runner::isRunning?(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

require_relative "KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require_relative "InMemoryWithOnDiskPersistenceValueCache.rb"

# -----------------------------------------------------------------

class Runner

    # Runner::isRunning?(uuid)
    def self.isRunning?(uuid)
        !InMemoryWithOnDiskPersistenceValueCache::getOrNull("db183530-293a-41f8-b260-283c59659bd5:#{uuid}").nil?
    end

    # Runner::runTimeInSecondsOrNull(uuid)
    def self.runTimeInSecondsOrNull(uuid)
        unixtime = InMemoryWithOnDiskPersistenceValueCache::getOrNull("db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
        return nil if unixtime.nil?
        Time.new.to_f - unixtime
    end

    # Runner::start(uuid)
    def self.start(uuid)
        return if Runner::isRunning?(uuid)
        InMemoryWithOnDiskPersistenceValueCache::set("db183530-293a-41f8-b260-283c59659bd5:#{uuid}", Time.new.to_i)
    end

    # Runner::stop(uuid)
    def self.stop(uuid)
        return nil if !Runner::isRunning?(uuid)
        unixtime = InMemoryWithOnDiskPersistenceValueCache::getOrNull("db183530-293a-41f8-b260-283c59659bd5:#{uuid}").to_i
        timespan = Time.new.to_f - unixtime
        InMemoryWithOnDiskPersistenceValueCache::delete( "db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
        timespan
    end
end
