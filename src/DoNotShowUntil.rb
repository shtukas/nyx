# encoding: UTF-8

class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uid, unixtime)
    def self.setUnixtime(uid, unixtime)
        KeyToStringOnDiskStore::set("/Users/pascal/Galaxy/DataBank/DoNotShowUntil", "80686672-0290-4a28-94d9-0381a7d2b4a9:#{uid}", unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uid)
    def self.getUnixtimeOrNull(uid)
        unixtime = KeyToStringOnDiskStore::getOrNull("/Users/pascal/Galaxy/DataBank/DoNotShowUntil", "80686672-0290-4a28-94d9-0381a7d2b4a9:#{uid}")
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
