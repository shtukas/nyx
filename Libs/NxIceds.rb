# encoding: UTF-8

class NxIceds

    # NxIceds::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "NxIced"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "description"),
            "nx111"       => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "nx111"),
        }
    end

    # NxIceds::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("NxIced")
    end

    # NxIceds::destroy(uuid)
    def self.destroy(uuid)
        Fx256::deleteObjectLogically(uuid)
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
