
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

        ax39 = Ax39::interactivelyCreateNewAx()

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
        count = TxNumbersAcceleration::count(item)
        "(project) #{item["description"]}#{nx111String} #{Ax39::toString(item)} (#{count})"
    end

    # TxProjects::tasks(project)
    def self.tasks(project)
        Nx07::owneruuidToTaskuuids(project["uuid"])
            .map{|uuid| Librarian::getObjectByUUIDOrNullEnforceUnique(uuid) }
            .compact
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

    # TxProjects::itemsForMainListing()
    def self.itemsForMainListing()
        TxProjects::items()
            .select{|item| Ax39::itemShouldShow(item) }
    end

    # ------------------------------------------------
    # Operations

    # TxProjects::selectTaskAndLanding(project)
    def self.selectTaskAndLanding(project)
        loop {
            system("clear")
            tasks = TxProjects::tasks(project)
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
                        .first(10)
            task = LucilleCore::selectEntityFromListOfEntitiesOrNull("task", tasks, lambda{|task| NxTasks::toString(task) })
            break if task.nil?
            Landing::implementsNx111Landing(task)
        }
    end

    # TxProjects::selectedSelfOrTaskAndStart(project)
    def self.selectedSelfOrTaskAndStart(project)
        items = nil
        if project["nx111"] then
            items = [project] + TxProjects::tasks(project)
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        else
            items = TxProjects::tasks(project)
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        end

        if items.size == 1 then
            LxAction::action("start", items[0])
            return
        end

        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| NxTasks::toString(item) })
        return if item.nil?
        LxAction::action("start", item)
    end

    # TxProjects::landing(project)
    def self.landing(project)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["landing", "access tasks"])
        return if action.nil?
        if action == "landing" then
            Landing::implementsNx111Landing(item)
        end
        if action == "access tasks" then
            TxProjects::selectTaskAndLanding(project)
        end
    end
end
