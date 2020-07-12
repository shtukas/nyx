
# encoding: UTF-8

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
