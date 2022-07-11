
# encoding: UTF-8

class TxProjects

    # ----------------------------------------------------------------------
    # IO

    # TxProjects::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxProject")
    end

    # TxProjects::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxProjects::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        nx111 = Nx111::interactivelyCreateNewNx111OrNull()

        ax39 = Ax39::interactivelyCreateNewAx("TxProject")

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "TxProject",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "ax39"        => ax39,
            "nx111"       => nx111
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # TxProjects::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        "(project) #{item["description"]}#{nx111String} #{Ax39::toString(item)}#{dnsustr}"
    end

    # TxProjects::nx20s()
    def self.nx20s()
        TxProjects::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{TxProjects::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end

    # ----------------------------------------------------------------------
    # Operations

    # TxProjects::dive()
    def self.dive()
        loop {
            project = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", TxProjects::items(), lambda{|item| TxProjects::toString(item) })
            break if project.nil?
            Landing::landing(project)
        }
    end

end
