
# encoding: UTF-8

class TxQueues

    # ----------------------------------------------------------------------
    # IO

    # TxQueues::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxQueue")
    end

    # TxQueues::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxQueues::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAx("TxQueue")

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "TxQueue",
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

    # TxQueues::queueSize(item)
    def self.queueSize(item)
        size = XCache::getOrNull("78fe9aa9-99b2-4430-913b-1512880bf323:#{item["uuid"]}")
        return size.to_i if size
        size = Nx07::principaluuidToTaskuuidsOrdered(item["uuid"]).size
        XCache::set("78fe9aa9-99b2-4430-913b-1512880bf323:#{item["uuid"]}", size)
        size
    end

    # TxQueues::toString(item)
    def self.toString(item)
        "(queue) #{item["description"]} #{Ax39::toString(item)} (#{TxQueues::queueSize(item)})"
    end

    # TxQueues::tasks(queue)
    def self.tasks(queue)
        Nx07::principaluuidToTaskuuidsOrdered(queue["uuid"])
            .map{|uuid| Librarian::getObjectByUUIDOrNullEnforceUnique(uuid) }
            .compact
    end

    # TxQueues::nx20s()
    def self.nx20s()
        TxQueues::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{TxQueues::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end

    # TxQueues::getFirstTasksOrNull(queue)
    def self.getFirstTasksOrNull(queue)

        adaptedRecovering = lambda {|item|
            rt = BankExtended::stdRecoveredDailyTimeInHours(item["uuid"])
            (rt == 0) ? 0.4 : rt
        }

        Nx07::principaluuidToTaskuuidsOrdered(queue["uuid"])
            .first(3)
            .map{|uuid|
                task = Librarian::getObjectByUUIDOrNullEnforceUnique(uuid)
                if task.nil? then
                    nil
                else
                    if task["mikuType"] != "NxTask" then
                        # Some maintenance:
                        # Happens when the task has been transformed to a Nyx node, but the link between
                        # the queue and the task still exists.
                        Nx07::unlink(queue["uuid"], task["uuid"])
                        nil
                    else
                        if DoNotShowUntil::isVisible(task["uuid"]) then
                            task
                        else
                            nil
                        end
                    end
                end
            }
            .compact
            .sort{|i1, i2| adaptedRecovering.call(i1) <=> adaptedRecovering.call(i2) }
            .first(1)
    end

    # TxQueues::itemsForMainListing()
    def self.itemsForMainListing()
        # We are not displaying the queues (they are independently displayed in section 1, for landing)
        # Instead we are displaying the first element of any queue that has not yet met they target
        TxQueues::items()
            .select{|item| Ax39::itemShouldShow(item) }
            .map{|queue| TxQueues::getFirstTasksOrNull(queue) }
            .flatten
            .compact
    end

    # ------------------------------------------------
    # Operations

    # TxQueues::landing(queue)
    def self.landing(queue)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["update description", "access tasks"])
        return if action.nil?
        if action == "update description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            queue["description"] = description
            Librarian::commit(queue)
        end
        if action == "access tasks" then
            TxQueues::queueDive(queue)
        end
    end

    # TxQueues::queueDive(queue)
    def self.queueDive(queue)
        loop {
            tasks = TxQueues::tasks(queue)
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

    # TxQueues::dive()
    def self.dive()
        loop {
            queue = LucilleCore::selectEntityFromListOfEntitiesOrNull("queue", TxQueues::items(), lambda{|item| TxQueues::toString(item) })
            break if queue.nil?
            TxQueues::landing(queue)
        }
    end
end
