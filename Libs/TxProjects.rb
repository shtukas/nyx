
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

        ax39 = Ax39::interactivelyCreateNewAx()

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "TxProject",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "ax39"        => ax39
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # TxProjects::toString(item)
    def self.toString(item)
        "(project) #{item["description"]} #{Ax39::toString(item)}"
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

    # TxProjects::selectedTaskAndStart(project)
    def self.selectedTaskAndStart(project)
        tasks = TxProjects::tasks(project)
                    .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        task = LucilleCore::selectEntityFromListOfEntitiesOrNull("task", tasks, lambda{|task| NxTasks::toString(task) })
        return if task.nil?
        LxAction::action("start", task)
    end

    # TxProjects::diving(project)
    def self.diving(project)
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

    # TxProjects::landing(project)
    def self.landing(project)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["update description", "access/dive"])
        return if action.nil?
        if action == "update description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            project["description"] = description
            Librarian::commit(project)
        end
        if action == "access/dive" then
            TxProjects::diving(project)
        end
    end
end
