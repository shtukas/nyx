
# encoding: UTF-8

class NxTimelines

    # ----------------------------------------------------------------------
    # IO

    # NxTimelines::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxTimeline")
    end

    # NxTimelines::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxTimelines::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "NxTimeline",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxTimelines::toString(item)
    def self.toString(item)
        "(timeline) #{item["description"]}"
    end

    # ------------------------------------------------
    # Nx20s

    # NxTimelines::nx20s()
    def self.nx20s()
        NxTimelines::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{NxTimelines::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
