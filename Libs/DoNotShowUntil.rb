# encoding: UTF-8

class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uid, unixtime)
    def self.setUnixtime(uid, unixtime)
        item = {
          "uuid"           => SecureRandom.uuid,
          "variant"        => SecureRandom.uuid,
          "mikuType"       => "NxDNSU",
          "unixtime"       => Time.new.to_i,
          "targetuuid"     => uid,
          "targetunixtime" => unixtime
        }
        Librarian::commit(item)
        XCache::set("86d82d66-de30-46e6-a7d3-7987b70b80e2:#{uid}", unixtime)
    end

    # DoNotShowUntil::incomingEvent(event)
    def self.incomingEvent(event)
        return if event["mikuType"] != "NxDNSU"
        uid = event["targetuuid"]
        existingUnixtimeOpt = DoNotShowUntil::getUnixtimeOrNull(uid)
        unixtime = event["targetunixtime"]
        if existingUnixtimeOpt then
            unixtime = [unixtime, existingUnixtimeOpt].max
        end
        XCache::set("86d82d66-de30-46e6-a7d3-7987b70b80e2:#{uid}", unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uid)
    def self.getUnixtimeOrNull(uid)
        unixtime = XCache::getOrNull("86d82d66-de30-46e6-a7d3-7987b70b80e2:#{uid}")
        if unixtime then
            return nil if unixtime == "null"
            return unixtime.to_i
        end

        #puts "DoNotShowUntil::getUnixtimeOrNull(#{uid})"

        unixtime = Librarian::getObjectsByMikuType("NxDNSU")
                        .select{|item| item["targetuuid"] == uid }
                        .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
                        .map{|item| item["targetunixtime"] }
                        .last

        if unixtime then
            XCache::set("86d82d66-de30-46e6-a7d3-7987b70b80e2:#{uid}", unixtime)
        else
            XCache::set("86d82d66-de30-46e6-a7d3-7987b70b80e2:#{uid}", "null")
        end

        unixtime
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
