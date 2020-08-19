# encoding: UTF-8

DoNotShowUntilDatabaseFilepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Do-Not-Show-Until.sqlite3"

class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uid, unixtime)
    def self.setUnixtime(uid, unixtime)
        Dionysus1::kvstore_set(DoNotShowUntilDatabaseFilepath, uid, unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uid)
    def self.getUnixtimeOrNull(uid)
        unixtime = Dionysus1::kvstore_getOrNull(DoNotShowUntilDatabaseFilepath, uid)
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
