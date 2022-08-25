
# encoding: UTF-8

class Streaming

    # Streaming::itemToNyx(itemuuid)
    def self.itemuuidToNyx(itemuuid)
        item = Fx256::getAliveProtoItemOrNull(itemuuid)
        return if item.nil?
        if !["NxTask", "NxIced"].include?(item["mikuType"]) then
            puts "I am authorised to >nyx only NxTasks and NxIceds in this function"
            LucilleCore::pressEnterToContinue()
            return
        end
        LxAction::action("stop", item["uuid"])
        Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxDataNode")
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
            command = LucilleCore::askQuestionAnswerAsString("    access, done, detach (running), (keep and) next (default), landing (and back), insert, >owner, >nyx, nyx: ")
            if command == "access" then
                LxAction::action("access", item)
                next
            end
            if command == "done" then
                LxAction::action("stop", item)
                Fx256::deleteObjectLogically(item["uuid"])
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
            if command == ">owner" then
                thread = TxTimeCommitmentProjects::architectOneOrNull()
                return if thread.nil?
                OwnerMapping::issue(thread["uuid"], item["uuid"])
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
            command = LucilleCore::askQuestionAnswerAsString("    run (start and access), access, landing (and back), done, insert, >owner, >nyx, nyx, next (default), exit (rstream): ")
            if command == "run" then
                return Streaming::runItem(item) # return: nil, "should-stop-rstream", "item-done"
            end
            if command == "access" then
                LxAction::action("access", item)
                next
            end
            if command == "landing" then
                LxAction::action("landing", item)
                next
            end
            if command == "done" then
                Fx256::deleteObjectLogically(item["uuid"])
                return "item-done"
            end
            if command == "insert" then
                Catalyst::primaryCommandProcess()
                next
            end
            if command == ">owner" then
                thread = TxTimeCommitmentProjects::architectOneOrNull()
                return if thread.nil?
                OwnerMapping::issue(thread["uuid"], item["uuid"])
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
            next if !OwnerMapping::elementuuidToOwnersuuids(item["uuid"]).empty?
            command = Streaming::processItem(item)
            break if command == "should-stop-rstream"
            break if BankExtended::stdRecoveredDailyTimeInHours(uuid) >= 1
        }
        NxBallsService::close(uuid, true)
    end

    # Streaming::listingItems()
    def self.listingItems()
        uuid = Streaming::uuid()
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        return [] if rt > 1
        [{
            "uuid" => uuid,
            "mikuType" => "(rstream-to-target)",
            "announce" => "(rstream, hour, rt: #{rt.round(1)}, #{BankExtended::lastWeekHoursDone(uuid).map{|n| n.round(2) }.join(", ")})"
        }]
    end
end
