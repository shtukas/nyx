
# encoding: UTF-8

class Streaming

    # Streaming::runItem(item) # return: nil, "should-stop-rstream", "item-done"
    def self.runItem(item)
        LxAction::action("start", item)
        LxAction::action("access", item)
        loop {
            command = LucilleCore::askQuestionAnswerAsString("(> #{LxFunction::function("toString", item).green}) done, detach (running), (keep and) next {default}, replace, >nyx: ")
            if command == "done" then
                LxAction::action("stop", item)
                LxAction::action("done", item, {"forcedone" => true})
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
            if command == "next" then
                LxAction::action("stop", item)
                return nil
            end
            if command == "replace" then
                if item["mikuType"] != "TxTodo" then
                    puts "I cannot replace something that is not a TxTodo item"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                TxTodos::interactivelyCreateNewOrNull()
                LxAction::action("stop", item)
                TxTodos::destroy(item)
                return nil
            end
            if command == ">nyx" then
                if item["mikuType"] != "TxTodo" then
                    puts "I cannot >nyx something that is not a TxTodo item"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                LxAction::action("stop", item)
                item["mikuType"] = "Nx100"
                item["i1as"] = [item["nx111"]]
                item["flavour"] = Nx102Flavor::interactivelyCreateNewFlavour()
                Librarian::commit(item)
                Nx100s::landing(item)
                Bank::put("todo-done-count-afb1-11ac2d97a0a8", 1) # The item has not been destroyed, it's just not a TxTodo anymore
                return nil
            end
        }
    end

    # Streaming::processItem(item) # return: nil, "should-stop-rstream", "item-done"
    def self.processItem(item)
        loop {
            command = LucilleCore::askQuestionAnswerAsString("(> #{LxFunction::function("toString", item).green}) run (start and access), landing (and back), done, return (default), exit (rstream): ")
            if command == "run" then
                return Streaming::runItem(item) # return: nil, "should-stop-rstream", "item-done"
            end
            if command == "landing" then
                LxAction::action("landing", item)
                item = Librarian::getObjectByUUIDOrNull(item["uuid"])
                if item.nil? then
                    return nil
                end
                if item["mikuType"] != "TxTodo" then
                    return nil
                end
                next
            end
            if command == "done" then
                LxAction::action("done", item, {"forcedone" => true})
                return "item-done"
            end
            if command == "" or command == "return" then
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
        uuid = "1ee2805a-f8ee-4a73-a92a-c76d9d45359a" # uuid of the Streaming::rstreamTokens()

        if !NxBallsService::isRunning(uuid) then
            NxBallsService::issue(uuid, "(rstream)" , [uuid]) # rstream itself doesn't publish time to bank accounts.
        end

        items = TxTodos::items().shuffle.take(20)
        Streaming::stream(items)

        NxBallsService::close(uuid, true)
    end

    # Streaming::rstreamTokens()
    def self.rstreamTokens()
        uuid = "1ee2805a-f8ee-4a73-a92a-c76d9d45359a" # uuid also used in TxTodos
        return [] if BankExtended::stdRecoveredDailyTimeInHours(uuid) > 1
        [{
            "uuid"     => uuid,
            "mikuType" => "(rstream)",
            "announce" => "(rstream) (#{Bank::valueOverTimespan("todo-done-count-afb1-11ac2d97a0a8", 86400*7)} last 7 days)",
            "lambda"   => lambda { Streaming::rstream() },
            "rt"       => BankExtended::stdRecoveredDailyTimeInHours(uuid)
        }]
    end
end
