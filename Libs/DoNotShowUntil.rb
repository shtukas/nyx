# encoding: UTF-8

# create table _dnsu_ (_uuid_ text, _unixtime_ float);

class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        XCache::set("acc88746-0f3b-45ec-83b4-b511cc1563a4:#{uuid}", unixtime)
        SystemEvents::broadcast({
            "mikuType"       => "NxDoNotShowUntil",
            "targetuuid"     => uuid,
            "targetunixtime" => unixtime
        })
    end

    # DoNotShowUntil::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "NxDoNotShowUntil" then
            FileSystemCheck::fsck_NxDoNotShowUntil(event, SecureRandom.hex, false)
            uuid     = event["targetuuid"]
            unixtime = event["targetunixtime"]
            XCache::set("acc88746-0f3b-45ec-83b4-b511cc1563a4:#{uuid}", unixtime)
        end
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        unixtime = XCache::getOrNull("acc88746-0f3b-45ec-83b4-b511cc1563a4:#{uuid}")
        unixtime ? unixtime.to_f : nil
    end

    # DoNotShowUntil::getDateTimeOrNull(uuid)
    def self.getDateTimeOrNull(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return nil if unixtime.nil?
        Time.at(unixtime).utc.iso8601
    end

    # DoNotShowUntil::isVisible(uuid)
    def self.isVisible(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return true if unixtime.nil?
        Time.new.to_i >= unixtime.to_i
    end
end
