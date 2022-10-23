# encoding: UTF-8

# create table _dnsu_ (_uuid_ text, _unixtime_ float);

class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxDoNotShowUntil",
            "unixtime" => unixtime
        }
        TheBook::commitObjectToDisk("#{Config::pathToDataCenter()}/DoNotShowUntil", item)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        object = TheBook::getObjectOrNull("#{Config::pathToDataCenter()}/DoNotShowUntil", uuid)
        return nil if object.nil?
        object["unixtime"]
    end

    # DoNotShowUntil::getDateTimeOrNull(uuid)
    def self.getDateTimeOrNull(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return nil if unixtime.nil?
        return nil if Time.new.to_i >= unixtime.to_i
        Time.at(unixtime).utc.iso8601
    end

    # DoNotShowUntil::isVisible(uuid)
    def self.isVisible(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return true if unixtime.nil?
        Time.new.to_i >= unixtime.to_i
    end
end
