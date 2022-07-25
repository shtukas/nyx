# encoding: UTF-8

class NxIceds

    # NxIceds::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxIced"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "nx111"       => Fx18Utils::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111")),
        }
    end

    # NxIceds::items()
    def self.items()
        Fx18Index2PrimaryLookup::mikuType2objectuuids("NxIced")
            .map{|objectuuid| Fx18Index2PrimaryLookup::itemOrNull(objectuuid)}
            .compact
    end

    # NxIceds::destroy(uuid)
    def self.destroy(uuid)
        Fx18::destroyObject(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxIceds::toString(item)
    def self.toString(item)
        builder = lambda{
            nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
            "(iced) #{item["description"]}#{nx111String}"
        }
        builder.call()
    end

    # NxIceds::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(iced) #{item["description"]}"
    end
end
