
# encoding: UTF-8

class NxEntities

    # ----------------------------------------------------------------------
    # IO

    # NxEntities::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxEntity")
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

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "NxEntity",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
        }
        Librarian::commit(item)
        item
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
