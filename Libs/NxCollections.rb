
# encoding: UTF-8

class NxCollections

    # ----------------------------------------------------------------------
    # IO

    # NxCollections::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxCollection")
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

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "NxCollection",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
        }
        Librarian::commit(item)
        item
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
