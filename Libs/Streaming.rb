
# encoding: UTF-8

class Streaming

    # Streaming::runItem(item) # return should_stop_rstream
    def self.runItem(item)
        LxAction::action("start", item)
        LxAction::action("access", item)
        returnvalue = nil
        loop {
            command = LucilleCore::askQuestionAnswerAsString("(> #{LxFunction::function("toString", item).green}) done, detach (running), (keep and) next, replace, universe, >nyx: ")
            next if command.nil?
            if command == "done" then
                LxAction::action("stop", item)
                if item["mikuType"] == "TxTodo" then
                    $RStreamProgressMonitor.anotherOne()
                end
                LxAction::action("done", item)
                return false
            end
            if command == "detach" then
                # We need to ensure that this thing has a low enough ordinal to be able to show up in the regular listing
                item["ordinal"] = 0
                Librarian::commit(item)
                return true
            end
            if command == "next" then
                LxAction::action("stop", item)
                return false
            end
            if command == "replace" then
                if item["mikuType"] != "TxTodo" then
                    puts "I cannot replace something that is not a TxTodo item"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                TxTodos::interactivelyCreateNewOrNull()
                LxAction::action("stop", item)
                TxTodos::destroy(item["uuid"])
                return false
            end
            if command == "universe" then
                item["universe"] = Multiverse::interactivelySelectUniverse()
                Librarian::commit(item)
                LxAction::action("stop", item)
                return false
            end
            if command == ">nyx" then
                if item["mikuType"] != "TxTodo" then
                    puts "I cannot >nyx something that is not a TxTodo item"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                LxAction::action("stop", item)
                item["mikuType"] = "Nx100"
                item["flavour"] = Nx102Flavor::interactivelyCreateNewFlavour()
                Librarian::commit(item)
                Nx100s::landing(item)
                $RStreamProgressMonitor.anotherOne()
                return false
            end
        }
    end

    # Streaming::processItem(item)
    def self.processItem(item)
        loop {
            command = LucilleCore::askQuestionAnswerAsString("(> #{LxFunction::function("toString", item).green}) run (start and access, default), landing (and back), done, universe, next, exit (rstream): ")
            if command == "" or command == "run" then
                return Streaming::runItem(item) # should_stop_rstream
            end
            if command == "landing" then
                LxAction::action("landing", item)
                item = Librarian::getObjectByUUIDOrNull(item["uuid"])
                if item.nil? then
                    return false
                end
                if item["mikuType"] != "TxTodo" then
                    return false
                end
                # Otherwise we restart the loop
            end
            if command == "done" then
                LxAction::action("done", item)
                if item["mikuType"] == "TxTodo" then
                    $RStreamProgressMonitor.anotherOne()
                end
                return false
            end
            if command == "universe" then
                item["universe"] = Multiverse::interactivelySelectUniverse()
                Librarian::commit(item)
                return false
            end
            if command == "next" then
                return false
            end
            if command == "exit" then
                return true
            end
        }
    end

    # Streaming::stream(items)
    def self.stream(items)
        items.each{|item| 
            should_stop_rstream = Streaming::processItem(item)
            break if should_stop_rstream
        }
    end

    # Streaming::rstream()
    def self.rstream()
        uuid = "1ee2805a-f8ee-4a73-a92a-c76d9d45359a" # uuid of the Streaming::rstreamToken()

        if !NxBallsService::isRunning(uuid) then
            NxBallsService::issue(uuid, "(rstream)" , [uuid]) # rstream itself doesn't publish time to bank accounts.
        end

        items = TxTodos::itemsForUniverse("standard").shuffle.take(20)
        Streaming::stream(items)

        NxBallsService::close(uuid, true)
    end

    # Streaming::rstreamToken()
    def self.rstreamToken()
        uuid = "1ee2805a-f8ee-4a73-a92a-c76d9d45359a" # uuid also used in TxTodos
        return [] if BankExtended::stdRecoveredDailyTimeInHours(uuid) > 1
        [{
            "uuid"     => uuid,
            "mikuType" => "(rstream)",
            "announce" => "(rstream) (#{$RStreamProgressMonitor.getCount()} last 7 days)",
            "lambda"   => lambda { Streaming::rstream() },
            "rt"       => BankExtended::stdRecoveredDailyTimeInHours(uuid)
        }]
    end
end
