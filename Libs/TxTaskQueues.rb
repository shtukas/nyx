
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
        "(queue) #{item["description"]}"
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

    # ------------------------------------------------
    # Operations

    # NxTask::access(queue)
    def self.access(queue)
        loop {
            system("clear")
            tasks = TxTaskQueues::tasks(queue).sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            task = LucilleCore::selectEntityFromListOfEntitiesOrNull("task", tasks, lambda{|task| NxTask::toString(task) })
            break if task.nil?
            puts "To be written, we need to start and access the task and give the time to the correct queue"
            exit
        }
    end

end
