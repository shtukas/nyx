
# encoding: UTF-8

class TxTaskQueues

    # ----------------------------------------------------------------------
    # IO

    # TxTaskQueues::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxTaskQueue")
    end

    # TxTaskQueues::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxTaskQueues::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAx()

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "TxTaskQueue",
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

    # TxTaskQueues::toString(item)
    def self.toString(item)
        count = TxNumbersAcceleration::count(item)
        "(queue) #{item["description"]} #{Ax39::toString(item)} (#{count})"
    end

    # TxTaskQueues::tasks(queue)
    def self.tasks(queue)
        Nx07::owneruuidToTaskuuids(queue["uuid"])
            .map{|uuid| Librarian::getObjectByUUIDOrNullEnforceUnique(uuid) }
            .compact
    end

    # TxTaskQueues::nx20s()
    def self.nx20s()
        TxTaskQueues::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{TxTaskQueues::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end

    # TxTaskQueues::getFirstTaskOrNull(queue)
    def self.getFirstTaskOrNull(queue)
        Nx07::owneruuidToTaskuuids(queue["uuid"]).each{|uuid|
            task = Librarian::getObjectByUUIDOrNullEnforceUnique(uuid)
            next if task.nil?
            if task["mikuType"] != "NxTask" then
                # Some maintenance:
                # Happens when the task has been transformed to a Nyx node, but the link between
                # the queue and the task still exists.
                Nx07::unlink(queue["uuid"], task["uuid"])
                next
            end
            return task if task
        }
        nil
    end

    # TxTaskQueues::itemsForMainListing()
    def self.itemsForMainListing()
        # We are not displaying the queues (they are independently displayed in section 1, for landing)
        # Instead we are displaying the first element of any queue that has not yet met they target
        TxTaskQueues::items()
            .select{|item| Ax39::itemShouldShow(item) }
            .map{|queue| TxTaskQueues::getFirstTaskOrNull(queue) }
            .compact
    end

    # ------------------------------------------------
    # Operations

    # TxTaskQueues::diving(queue)
    def self.diving(queue)
        loop {
            tasks = TxTaskQueues::tasks(queue)
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
                        .first(10)
            if tasks.size == 0 then
                puts "no tasks found for '#{project["description"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            task = LucilleCore::selectEntityFromListOfEntitiesOrNull("task", tasks, lambda{|task| NxTasks::toString(task) })
            break if task.nil?
            Landing::implementsNx111Landing(task)
        }
    end

    # TxTaskQueues::landing(queue)
    def self.landing(queue)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["update description", "access tasks"])
        return if action.nil?
        if action == "update description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            queue["description"] = description
            Librarian::commit(queue)
        end
        if action == "access tasks" then
            TxTaskQueues::diving(queue)
        end
    end
end
