
# encoding: UTF-8

class NxConcepts

    # ----------------------------------------------------------------------
    # IO

    # NxConcepts::objectuuidToItem(objectuuid)
    def self.objectuuidToItem(objectuuid)
        item = {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18s::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18s::getAttributeOrNull(objectuuid, "datetime"),
            "description" => Fx18s::getAttributeOrNull(objectuuid, "description")
        }
        raise "(error: 2e011d91-4842-413f-8f1f-02920b3b155a) item: #{item}" if item["mikuType"] != "NxConcept"
        item
    end

    # NxConcepts::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxConcept").map{|objectuuid|
            NxConcepts::objectuuidToItem(objectuuid)
        }
    end

    # NxConcepts::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyFx18Logically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxConcepts::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        uuid = SecureRandom.uuid

        Fx18s::makeNewFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxConcept")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    datetime)
        Fx18s::setAttribute2(uuid, "description", description)

        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxConcepts::toString(item)
    def self.toString(item)
        "(entity) #{item["description"]}"
    end

    # ------------------------------------------------
    # Nx20s

    # NxConcepts::nx20s()
    def self.nx20s()
        NxConcepts::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{NxConcepts::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
