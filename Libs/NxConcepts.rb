
# encoding: UTF-8

class NxConcepts

    # ----------------------------------------------------------------------
    # IO

    # NxConcepts::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxConcept")
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

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "NxConcept",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
        }
        Librarian::commit(item)
        item
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
