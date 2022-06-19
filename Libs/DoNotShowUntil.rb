# encoding: UTF-8

class DoNotShowUntilDataCenter

    def initialize()
        @data = nil
    end

    def reset()
        @data = []
    end

    def incoming(item)
        @data << item
    end

    def rebuild()
        reset()
        Librarian::getObjectsByMikuType("NxDNSU").each{|item|
            incoming(item)
        }
    end

    def data()
        if @data.nil? then
            rebuild()
        end
        @data
    end
end

$DoNotShowUntilDataCenter = DoNotShowUntilDataCenter.new()

class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uid, unixtime)
    def self.setUnixtime(uid, unixtime)
        item = {
          "uuid"           => SecureRandom.uuid,
          "mikuType"       => "NxDNSU",
          "unixtime"       => Time.new.to_i,
          "targetuuid"     => uid,
          "targetunixtime" => unixtime
        }
        Librarian::commit(item)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uid)
    def self.getUnixtimeOrNull(uid)
        $DoNotShowUntilDataCenter.data()
            .select{|item| item["targetuuid"] == uid }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
            .map{|item| item["targetunixtime"] }
            .last
    end

    # DoNotShowUntil::getDateTimeOrNull(uid)
    def self.getDateTimeOrNull(uid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uid)
        return nil if unixtime.nil?
        Time.at(unixtime).utc.iso8601
    end

    # DoNotShowUntil::isVisible(uid)
    def self.isVisible(uid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uid)
        return true if unixtime.nil?
        Time.new.to_i >= unixtime.to_i
    end
end
