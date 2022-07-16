
# encoding: UTF-8

class NxLines

    # ----------------------------------------------------------------------
    # IO

    # NxLines::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxLine").each{|objectuuid|
            {
                "uuid"        => objectuuid,
                "mikuType"    => "NxLine",
                "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
                "line"        => Fx18s::getAttributeOrNull(objectuuid, "line"),
            }
        }
    end

    # ----------------------------------------------------------------------
    # Makers

    # NxLines::issue(line)
    def self.issue(line)
        uuid = SecureRandom.uuid
        Fx18s::ensureFile(uuid)
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
