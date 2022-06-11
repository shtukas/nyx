
# encoding: UTF-8

class NxNavigation

    # NxNavigation::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxNavigation")
    end

    # NxNavigation::getOrNull(uuid): null or NxDataNode
    def self.getOrNull(uuid)
        Librarian::getObjectByUUIDOrNull(uuid)
    end

    # NxNavigation::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # ------------------------------------------------
    # Makers

    # NxNavigation::issue(description)
    def self.issue(description)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxNavigation",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description
        }
        Librarian::commit(item)
        item
    end

    # NxNavigation::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxNavigation::issue(description)
    end

    # NxNavigation::toString(item)
    def self.toString(item)
        "(nav) #{item["description"]}"
    end

    # ------------------------------------------------
    # Nx20s

    # NxNavigation::nx20s()
    def self.nx20s()
        NxNavigation::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{NxNavigation::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
