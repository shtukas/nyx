
# encoding: UTF-8

class NxConcepts

    # ----------------------------------------------------------------------
    # IO

    # NxConcepts::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxConcept").each{|objectuuid|
            {
                "uuid"        => objectuuid,
                "mikuType"    => "NxConcept",
                "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
                "datetime"    => Fx18s::getAttributeOrNull(objectuuid, "datetime"),
                "description" => Fx18s::getAttributeOrNull(objectuuid, "description")
            }
        }
    end

    # NxConcepts::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyEntity(uuid)
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

        Fx18s::ensureFile(uuid)
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
