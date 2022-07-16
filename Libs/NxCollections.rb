
# encoding: UTF-8

class NxCollections

    # ----------------------------------------------------------------------
    # IO

    # NxCollections::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxCollection").map{|objectuuid|
            {
                "uuid"        => objectuuid,
                "mikuType"    => "NxCollection",
                "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
                "datetime"    => Fx18s::getAttributeOrNull(objectuuid, "datetime"),
                "description" => Fx18s::getAttributeOrNull(objectuuid, "description")
            }
        }
    end

    # NxCollections::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyEntity(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxCollections::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        uuid = SecureRandom.uuid

        Fx18s::ensureFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxCollection")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    datetime)
        Fx18s::setAttribute2(uuid, "description", description)

        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxCollections::toString(item)
    def self.toString(item)
        "(collection) #{item["description"]}"
    end

    # ------------------------------------------------
    # Nx20s

    # NxCollections::nx20s()
    def self.nx20s()
        NxCollections::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{NxCollections::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
