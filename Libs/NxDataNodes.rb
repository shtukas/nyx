
# encoding: UTF-8

class NxDataNodes

    # ----------------------------------------------------------------------
    # IO

    # NxDataNodes::objectuuidToItem(objectuuid)
    def self.objectuuidToItem(objectuuid)
        item = {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18s::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18s::getAttributeOrNull(objectuuid, "datetime"),
            "description" => Fx18s::getAttributeOrNull(objectuuid, "description"),
            "nx111"       => JSON.parse(Fx18s::getAttributeOrNull(objectuuid, "nx111")),
        }
        raise "(error: 9e91a609-dc64-4bcb-9e64-fa11121c07d8) item: #{item}" if item["mikuType"] != "NxDataNode"
        item
    end

    # NxDataNodes::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxDataNode").map{|objectuuid|
            NxDataNodes::objectuuidToItem(objectuuid)
        }
    end

    # NxDataNodes::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyFx18Logically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxDataNodes::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        Fx18s::makeNewFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxDataNode")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    datetime)
        Fx18s::setAttribute2(uuid, "description", description)
        Fx18s::setAttribute2(uuid, "nx111",       JSON.generate(nx111))

        uuid
    end

    # NxDataNodes::issueNewItemAionPointFromLocation(location)
    def self.issueNewItemAionPointFromLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToAionPointNx111OrNull(uuid, location)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        Fx18s::makeNewFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxDataNode")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    datetime)
        Fx18s::setAttribute2(uuid, "description", description)
        Fx18s::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
        
        uuid
    end

    # NxDataNodes::issuePrimitiveFileFromLocationOrNull(location)
    def self.issuePrimitiveFileFromLocationOrNull(location)
        description = nil

        uuid = SecureRandom.uuid

        nx111 = PrimitiveFiles::locationToPrimitiveFileNx111OrNull(uuid, location)

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        Fx18s::makeNewFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxDataNode")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    datetime)
        Fx18s::setAttribute2(uuid, "description", description)
        Fx18s::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
        
        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxDataNodes::toString(item)
    def self.toString(item)
        "(data) #{item["description"]}"
    end

    # ------------------------------------------------
    # Nx20s

    # NxDataNodes::nx20s()
    def self.nx20s()
        NxDataNodes::items()
            .select{|item| !item["description"].nil? }
            .map{|item| 
                {
                    "announce" => "(#{item["uuid"][0, 4]}) #{NxDataNodes::toString(item)}",
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
