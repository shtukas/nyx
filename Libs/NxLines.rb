
# encoding: UTF-8

class NxLines

    # ----------------------------------------------------------------------
    # IO

    # NxLines::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18File::getAttributeOrNull(objectuuid, "mikuType") != "NxLine"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18File::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18File::getAttributeOrNull(objectuuid, "unixtime"),
            "line"        => Fx18File::getAttributeOrNull(objectuuid, "line"),
        }
    end

    # NxLines::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxLine")
            .map{|objectuuid| NxLines::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # ----------------------------------------------------------------------
    # Makers

    # NxLines::issue(line)
    def self.issue(line)
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxLine")
        Fx18File::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18File::setAttribute2(uuid, "line",        line)
        uuid
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
