
# encoding: UTF-8

class Streaming

    # Streaming::itemToNyx(itemuuid)
    def self.itemuuidToNyx(itemuuid)
        item = Fx18::itemOrNull(itemuuid)
        return if item.nil?
        if !["NxTask", "NxIced"].include?(item["mikuType"]) then
            puts "I am authorised to >nyx only NxTasks and NxIceds in this function"
            LucilleCore::pressEnterToContinue()
            return
        end
        LxAction::action("stop", item["uuid"])
        Fx18Attributes::set2(item["uuid"], "mikuType", "NxDataNode")
        LxAction::action("landing", item)
    end

    # Streaming::runItem(item) # return: nil, "should-stop-rstream", "item-done"
    def self.runItem(item)
        puts LxFunction::function("toString", item).green
        LxAction::action("start", item)
        LxAction::action("access", item)
        firstLoop = true
        loop {
            if !firstLoop then
                puts LxFunction::function("toString", item).green
            end
            firstLoop = false
            command = LucilleCore::askQuestionAnswerAsString("    done, detach (running), (keep and) next (default), landing (and back), insert, >project, >nyx, nyx: ")
            if command == "done" then
                LxAction::action("stop", item)
                Fx18::destroyObject(item["uuid"])
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
            if command == "landing" then
                LxAction::action("landing", item)
                next
            end
            if command == "insert" then
                Catalyst::primaryCommandProcess()
                next
            end
            if command == ">project" then
                project = TxProjects::architectOneOrNull()
                return if project.nil?
                TxProjects::addElement_v1(project["uuid"], item["uuid"])
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
                LxAction::action("landing", item)
                next
            end
            if command == "done" then
                Fx18::destroyObject(item["uuid"])
                return "item-done"
            end
            if command == "insert" then
                Catalyst::primaryCommandProcess()
                next
            end
            if command == ">project" then
                project = TxProjects::architectOneOrNull()
                return if project.nil?
                TxProjects::addElement_v1(project["uuid"], item["uuid"])
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

    # Streaming::stream(items)
    def self.stream(items)
        items.each{|item| 
            directive = Streaming::processItem(item) # return: nil, "should-stop-rstream", "item-done"
            if directive == "should-stop-rstream" then
                return
            end
        }
    end

    # Streaming::uuid()
    def self.uuid()
        "1ee2805a-f8ee-4a73-a92a-c76d9d45359a"
    end

    # Streaming::icedStreamingToTarget()
    def self.icedStreamingToTarget()
        uuid = Streaming::uuid()
        NxBallsService::issue(uuid, "(rstream-to-target)", [uuid])
        items = NxIceds::items().shuffle
        return if items.empty?
        loop {
            item = items.shift
            next if TxProjects::uuidIsProjectElement(item["uuid"])
            command = Streaming::processItem(item)
            break if command == "should-stop-rstream"
            break if BankExtended::stdRecoveredDailyTimeInHours(uuid) >= 1
        }
        NxBallsService::close(uuid, true)
    end

    # Streaming::icedStreamingToInfinity()
    def self.icedStreamingToInfinity()
        uuid = Streaming::uuid()
        NxBallsService::issue(uuid, "(rstream-to-infinity)", [uuid])
        items = NxIceds::items().shuffle
        loop {
            item = items.shift
            next if TxProjects::uuidIsProjectElement(item["uuid"])
            command = Streaming::runItem(item)
        }
        NxBallsService::close(uuid, true)
    end

    # Streaming::section2()
    def self.section2()
        uuid = Streaming::uuid()
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        return [] if rt > 1

        item = {
            "uuid" => uuid,
            "mikuType" => "(rstream-to-target)",
            "announce" => "(rstream, hour, rt: #{rt.round(1)}, #{BankExtended::lastWeekHoursDone(uuid).map{|n| n.round(2) }.join(", ")})"
        }

        [{
            "item" => item,
            "toString" => item["announce"],
            "metric"   => 0.6 + Catalyst::idToSmallShift(item["uuid"])
        }]
    end
end
