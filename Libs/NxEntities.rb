
# encoding: UTF-8

class NxEntities

    # ----------------------------------------------------------------------
    # IO

    # NxEntities::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxEntity").each{|objectuuid|
            {
                "uuid"        => objectuuid,
                "mikuType"    => "NxEntity",
                "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
                "datetime"    => Fx18s::getAttributeOrNull(objectuuid, "datetime"),
                "description" => Fx18s::getAttributeOrNull(objectuuid, "description")
            }
        }
    end

    # NxEntities::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyEntity(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxEntities::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        uuid = SecureRandom.uuid

        Fx18s::ensureFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxEntity")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    datetime)
        Fx18s::setAttribute2(uuid, "description", description)

        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxEntities::toString(item)
    def self.toString(item)
        "(entity) #{item["description"]}"
    end

    # ------------------------------------------------
    # Nx20s

    # NxEntities::nx20s()
    def self.nx20s()
        NxEntities::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{NxEntities::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
