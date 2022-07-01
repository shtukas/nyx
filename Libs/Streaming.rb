
# encoding: UTF-8

class Streaming

    # Streaming::runItem(item) # return: nil, "should-stop-rstream", "item-done"
    def self.runItem(item)
        LxAction::action("start", item)
        LxAction::action("access", item)
        loop {
            command = LucilleCore::askQuestionAnswerAsString("(> #{LxFunction::function("toString", item).green}) done/.., detach (running), (keep and) next (default), >queue, >nyx: ")
            if command == ".." or command == "done" then
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
            if command == ">queue" then
                owner = Nx07::architectOwnerOrNull()
                return if owner.nil?
                Nx07::issue(owner["uuid"], item["uuid"])
                return nil
            end
            if command == ">nyx" then
                if item["mikuType"] != "NxTask" then
                    puts "I cannot >nyx something that is not a NxTask"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                LxAction::action("stop", item)
                item["mikuType"] = "NxDataNode"
                item["nx111"] = item["nx111"]
                Librarian::commit(item)
                LxAction::action("landing", item)
                Bank::put("todo-done-count-afb1-11ac2d97a0a8", 1) # The item has not been destroyed, it's just not a NxTask anymore
                return nil
            end
        }
    end

    # Streaming::processItem(item) # return: nil, "should-stop-rstream", "item-done"
    def self.processItem(item)
        loop {
            command = LucilleCore::askQuestionAnswerAsString("#{LxFunction::function("toString", item).green} $ run/.. (start and access), landing (and back), done, next (default), exit (rstream): ")
            if command == ".." or command == "run" then
                return Streaming::runItem(item) # return: nil, "should-stop-rstream", "item-done"
            end
            if command == "landing" then
                LxAction::action("landing", item)
                item = Librarian::getObjectByUUIDOrNullEnforceUnique(item["uuid"])
                if item.nil? then
                    return nil
                end
                if item["mikuType"] != "NxTask" then
                    return nil
                end
                next
            end
            if command == "done" then
                NxTasks::destroy(item["uuid"])
                return "item-done"
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

    # Streaming::rstream()
    def self.rstream()
        NxBallsService::issue("1ee2805a-f8ee-4a73-a92a-c76d9d45359a", "(rstream)", ["1ee2805a-f8ee-4a73-a92a-c76d9d45359a"])
        items = NxTasks::items()
                    .shuffle
                    .take(20)
                    .select{|item| !Nx07::taskHasOwner(item) } # we only select items that are not already in a queue or in a project
        Streaming::stream(items)
        NxBallsService::close("1ee2805a-f8ee-4a73-a92a-c76d9d45359a", true)
    end

    # Streaming::listingItemForAnHour()
    def self.listingItemForAnHour()
        uuid = "1ee2805a-f8ee-4a73-a92a-c76d9d45359a"
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        return [] if rt >= 1
        [{
            "uuid" => uuid,
            "mikuType" => "(rstream)",
            "announce" => "(rstream, hour, rt: #{rt.round(1)})"
        }]
    end

    # Streaming::listingItemInfinity()
    def self.listingItemInfinity()
        uuid = "b8f2a945-9b7f-42d8-99d2-676f2822254a"
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        return [] if rt < 1
        [{
            "uuid" => uuid,
            "mikuType" => "(rstream)",
            "announce" => "(rstream, infinity, rt: #{rt.round(1)})"
        }]
    end
end
