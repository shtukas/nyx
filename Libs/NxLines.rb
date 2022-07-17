
# encoding: UTF-8

class NxLines

    # ----------------------------------------------------------------------
    # IO

    # NxLines::objectuuidToItem(objectuuid)
    def self.objectuuidToItem(objectuuid)
        item = {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18s::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
            "line"        => Fx18s::getAttributeOrNull(objectuuid, "line"),
        }
        raise "(error: e495b2cf-1c63-4bdb-9461-de116ed036cf) item: #{item}" if item["mikuType"] != "NxLine"
        item
    end

    # NxLines::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxLine").map{|objectuuid|
            NxLines::objectuuidToItem(objectuuid)
        }
    end

    # ----------------------------------------------------------------------
    # Makers

    # NxLines::issue(line)
    def self.issue(line)
        uuid = SecureRandom.uuid
        Fx18s::makeNewFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxLine")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "line",        line)
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
