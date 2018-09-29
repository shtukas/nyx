
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

=begin
    Canary exists because lists are not notified of an object having been discarded.
    Lists will know whether or not an object has not been seen for a while using Canary. 
=end

class Canary
    # Canary::mark(objectuuid)
    def self.mark(objectuuid)
        unixtime = Time.new.to_i
        KeyValueStore::set(nil, "7b748ba4-6ef1-463c-97fc-19186bbeb1d0:#{objectuuid}", Time.new.to_i)
        unixtime
    end
    # Canary::getLastSeenUnixtimeOrNull(objectuuid)
    def self.getLastSeenUnixtimeOrNull(objectuuid)
        unixtime = KeyValueStore::getOrNull(nil, "7b748ba4-6ef1-463c-97fc-19186bbeb1d0:#{objectuuid}")
        return nil if unixtime.nil?
        unixtime.to_i
    end
    # Canary::isAlive(objectuuid)
    def self.isAlive(objectuuid)
        unixtime = Canary::getLastSeenUnixtimeOrNull(objectuuid)
        if unixtime.nil? then
            unixtime = Canary::mark(objectuuid)
        end
        (Time.new.to_i - unixtime) > 86400*7 
    end
end
