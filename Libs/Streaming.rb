
# encoding: UTF-8

class Streaming

    # Streaming::itemToNyx(itemuuid)
    def self.itemuuidToNyx(itemuuid)
        if Fx18s::getAttributeOrNull(itemuuid, "mikuType") != "NxTask" then
            puts "I cannot >nyx something that is not a NxTask"
            LucilleCore::pressEnterToContinue()
            return
        end
        LxAction::action("stop", itemuuid)
        Fx18s::setAttribute2(itemuuid, "mikuType", "NxDataNode")
        LxAction::action("landing2", itemuuid)
    end

    # Streaming::runItem(item) # return: nil, "should-stop-rstream", "item-done"
    def self.runItem(item)
        puts LxFunction::function("toString", item).green
        LxAction::action("start", item)
        LxAction::action("access", item)
        loop {
            command = LucilleCore::askQuestionAnswerAsString("    done, detach (running), (keep and) next (default), insert, >project, >nyx, nyx: ")
            if command == "done" then
                LxAction::action("stop", item)
                NxTasks::destroy(item["uuid"])
                return "item-done"
            end
            if command == "detach" then
                todoCachedItems = JSON.parse(XCache::getOrDefaultValue("afb34ada-3ca5-4bc0-83f9-2b81ad7efb4b:#{date}", "[]"))
                if !todoCachedItems.map{|item| item["uuid"] }.include?(item["uuid"]) then
                    todoCachedItems << item
                    XCache::set("afb34ada-3ca5-4bc0-83f9-2b81ad7efb4b:#{date}", JSON.generate(todoCachedItems))
                end
                return "should-stop-rstream"
            end
            if command == "" or command == "next" then
                LxAction::action("stop", item)
                return nil
            end
            if command == "insert" then
                Catalyst::primaryCommandProcess()
                next
            end
            if command == ">project" then
                projectuuid = TxProjects::architectOneOrNull()
                return if projectuuid.nil?
                TxProjects::addElement(projectuuid, item["uuid"])
                NxBallsService::close(item["uuid"], true)
                return nil
            end
            if command == ">nyx" then
                Streaming::itemToNyx(item["uuid"])
                return nil
            end
            if command == "nyx" then
                Nyx::program()
                next
            end
        }
    end

    # Streaming::processItem(item) # return: nil, "should-stop-rstream", "item-done"
    def self.processItem(item)
        puts LxFunction::function("toString", item).green
        loop {
            command = LucilleCore::askQuestionAnswerAsString("    run (start and access), landing (and back), done, insert, >project, >nyx, nyx, next (default), exit (rstream): ")
            if command == "run" then
                return Streaming::runItem(item) # return: nil, "should-stop-rstream", "item-done"
            end
            if command == "landing" then
                LxAction::action("landing2", item["uuid"])
                next
            end
            if command == "done" then
                NxTasks::destroy(item["uuid"])
                return "item-done"
            end
            if command == "insert" then
                Catalyst::primaryCommandProcess()
                next
            end
            if command == ">project" then
                projectuuid = TxProjects::architectOneOrNull()
                return if projectuuid.nil?
                TxProjects::addElement(projectuuid, item["uuid"])
                return nil
            end
            if command == ">nyx" then
                Streaming::itemToNyx(item["uuid"])
                return nil
            end
            if command == "nyx" then
                Nyx::program()
                next
            end
            if command == "" or command == "next" then
                return nil
            end
            if command == "exit" then
                return "should-stop-rstream"
            end
        }
    end

    # Streaming::runstream(items)
    def self.runstream(items)
        items.each{|item| 
            directive = Streaming::processItem(item) # return: nil, "should-stop-rstream", "item-done"
            if directive == "should-stop-rstream" then
                return
            end
        }
    end

    # Streaming::rstreamUUID()
    def self.rstreamUUID()
        "1ee2805a-f8ee-4a73-a92a-c76d9d45359a"
    end

    # Streaming::rstreamToTarget()
    def self.rstreamToTarget()
        uuid = Streaming::rstreamUUID()
        NxBallsService::issue(uuid, "(rstream-to-target)", [uuid])
        items = NxTasks::items().shuffle
        loop {
            item = items.shift
            next if TxProjects::uuidIsProjectElement(item["uuid"])
            command = Streaming::runItem(item)
            break if command == "should-stop-rstream"
            break if BankExtended::stdRecoveredDailyTimeInHours(uuid) >= 1
        }
        NxBallsService::close(uuid, true)
    end

    # Streaming::rstreamToInfinity()
    def self.rstreamToInfinity()
        uuid = Streaming::rstreamUUID()
        NxBallsService::issue(uuid, "(rstream-to-infinity)", [uuid])
        items = NxTasks::items().shuffle
        loop {
            item = items.shift
            next if TxProjects::uuidIsProjectElement(item["uuid"])
            command = Streaming::runItem(item)
        }
        NxBallsService::close(uuid, true)
    end

    # Streaming::section1()
    def self.section1()
        uuid = Streaming::rstreamUUID()
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        if rt < 1 then
            return []
        end
        [{
            "uuid" => uuid,
            "unixtime" => Time.new.to_i,
            "mikuType" => "(rstream-to-target)",
            "announce" => "(rstream, hour, rt: #{rt.round(1)}, #{BankExtended::lastWeekHoursDone(uuid).map{|n| n.round(2) }.join(", ")})"
        }]
    end

    # Streaming::section2Xp()
    def self.section2Xp()
        uuid = Streaming::rstreamUUID()
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        if rt >= 1 then
            Listing::remove(uuid)
            [
                [], 
                [uuid]
            ]
        else
            [
                [{
                    "uuid" => uuid,
                    "mikuType" => "(rstream-to-target)",
                    "announce" => "(rstream, hour, rt: #{rt.round(1)}, #{BankExtended::lastWeekHoursDone(uuid).map{|n| n.round(2) }.join(", ")})"
                }],
                []
            ]
        end
    end
end
