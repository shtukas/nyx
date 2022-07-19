
# encoding: UTF-8

class NxLines

    # ----------------------------------------------------------------------
    # IO

    # NxLines::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxLine"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "line"        => Fx18Attributes::getOrNull(objectuuid, "line"),
        }
    end

    # NxLines::items()
    def self.items()
        Fx18Index1::mikuType2objectuuids("NxLine")
            .map{|objectuuid| NxLines::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # ----------------------------------------------------------------------
    # Makers

    # NxLines::issue(line)
    def self.issue(line)
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        Fx18Attributes::setAttribute2(uuid, "uuid",        uuid)
        Fx18Attributes::setAttribute2(uuid, "mikuType",    "NxLine")
        Fx18Attributes::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setAttribute2(uuid, "line",        line)
        item = NxLines::objectuuidToItemOrNull(uuid)
        raise "(error: 1853d31a-bb37-46d6-b4c2-7afcf88e0c56) How did that happen?" if item.nil?
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxLines::toString(item)
    def self.toString(item)
        "(line) #{item["line"]}"
    end

    # NxLines::section2()
    def self.section2()
        NxLines::items().select{|item| !TxProjects::uuidIsProjectElement(item["uuid"]) }
    end
end
