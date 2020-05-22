# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require 'time'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)

    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uid, unixtime)
    def self.setUnixtime(uid, unixtime)
        KeyValueStore::set("/Users/pascal/Galaxy/DataBank/DoNotShowUntil", "80686672-0290-4a28-94d9-0381a7d2b4a9:#{uid}", unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uid)
    def self.getUnixtimeOrNull(uid)
        unixtime = KeyValueStore::getOrNull("/Users/pascal/Galaxy/DataBank/DoNotShowUntil", "80686672-0290-4a28-94d9-0381a7d2b4a9:#{uid}")
        return nil if unixtime.nil?
        unixtime.to_i
    end

    # DoNotShowUntil::isVisible(uid)
    def self.isVisible(uid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uid)
        return true if unixtime.nil?
        Time.new.to_i >= unixtime.to_i
    end
end
