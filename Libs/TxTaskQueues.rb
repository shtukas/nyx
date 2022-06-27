
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
            "ax39"        => ax39,
            "tasks"       => []
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # TxTaskQueues::toString(item)
    def self.toString(item)
        "(queue) #{item["description"]} #{Ax39::toString(item)}"
    end

    # TxTaskQueues::tasks(queue)
    def self.tasks(queue)
        queue["tasks"]
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
        queue["tasks"].each{|uuid|
            task = Librarian::getObjectByUUIDOrNullEnforceUnique(uuid)
            return task if task
        }
        nil
    end

    # TxTaskQueues::tasksForSection2Listing()
    def self.tasksForSection2Listing()
        # We are not displaying the queues (they are independently displayed in section 1, for landing)
        # Instead we are displaying the first element of any queue that has not yet met they target
        TxTaskQueues::items()
            .select{|item| Ax39::itemShouldShow(item) }
            .map{|queue| TxTaskQueues::getFirstTaskOrNull(queue) }
            .compact
    end

    # TxTaskQueues::architectQueueOrNull()
    def self.architectQueueOrNull()
        queues = TxTaskQueues::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        queue = LucilleCore::selectEntityFromListOfEntitiesOrNull("queue", queues, lambda{|queue| TxTaskQueues::toString(queue) })
        return queue if queue
        TxTaskQueues::interactivelyIssueNewItemOrNull()
    end

    # TxTaskQueues::getQueueForTaskOrNull(task)
    def self.getQueueForTaskOrNull(task)
        TxTaskQueues::items()
            .select{|queue| queue["tasks"].include?(task["uuid"]) }
            .first
    end

    # ------------------------------------------------
    # Operations

    # TxTaskQueues::queuesDiving()
    def self.queuesDiving()
        loop {
            system("clear")
            queue = TxTaskQueues::architectQueueOrNull()
            break if queue.nil?
            puts "To be written, we need to start and access the task and give the time to the correct queue"
            exit
        }
    end

    # TxTaskQueues::queueDiving(queue)
    def self.queueDiving(queue)
        loop {
            system("clear")
            tasks = TxTaskQueues::tasks(queue)
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
                        .first(10)
            task = LucilleCore::selectEntityFromListOfEntitiesOrNull("task", tasks, lambda{|task| NxTasks::toString(task) })
            break if task.nil?
            Landing::implementsNx111Landing(task)
        }
    end

    # TxTaskQueues::landing(queue)
    def self.landing(queue)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["update description", "access/dive"])
        return if action.nil?
        if action == "update description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            queue["description"] = description
            Librarian::commit(queue)
        end
        if action == "access/dive" then
            TxTaskQueues::queueDiving(queue)
        end
    end
end
