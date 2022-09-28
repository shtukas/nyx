# encoding: UTF-8

=begin
Lx13 = {
    "name"        => Nx53
    "cr"          => Float
    "bankaccount" => String
}
=end

class CatalystGroupMonitor
    def initialize()
        @lx13s = []
        @lx13s = XCacheValuesWithExpiry::getOrNull("abc03773-bdca-4c5d-86e9-92a253f3e239")
        if @lx13s.nil? then
            rebuildLx13sFromScratch()
        end
        Thread.new {
            loop {
                sleep 300
                rebuildLx13sFromScratch()
            }
        }
    end

    def getLx13sForDisplay()
        @lx13s
            .select{|packet| packet["cr"] < 1 }
            .select{|packet| 
                bankaccount = packet["bankaccount"]
                !BankAccountDoneForToday::isDoneToday(bankaccount) 
            }
            .sort{|p1, p2| p1["cr"] <=> p2["cr"] }
    end

    def rebuildLx13sFromScratch()
        @lx13s = Nx11EListingMonitorUtils::nx53s().map{|nx53|
            name1 = (lambda{|nx53|
                if nx53["mikuType"] == "Ax39Group" then
                    return nx53["name"]
                end
                if nx53["mikuType"] == "NxTodo" then
                    return nx53["description"]
                end
            }).call(nx53)
            bankaccount = (lambda{|nx53|
                if nx53["mikuType"] == "Ax39Group" then
                    return nx53["account"]
                end
                if nx53["mikuType"] == "NxTodo" then
                    return nx53["nx11e"]["itemuuid"]
                end
            }).call(nx53)
            {
                "name"        => name1,
                "cr"          => Nx11EListingMonitorUtils::nx53ToCompletionRatio(nx53),
                "bankaccount" => bankaccount
            }
        }
        XCacheValuesWithExpiry::set("abc03773-bdca-4c5d-86e9-92a253f3e239", @lx13s, nil)
    end
end

=begin
Lx12 = {
    "item"     => Item
    "priority" => Float
    "announce" => string # Should be the toString of the item
}
=end

class CatalystAlfred

    def initialize()
        @lx12s = []
        # let's start by using cached listing for speed
        @lx12s = XCacheValuesWithExpiry::getOrNull("968dceb4-a0a9-4ffa-9b17-9b74a34e6bd9")
        if @lx12s.nil? then
            rebuildLx12sFromStratch()
        end
        Thread.new {
            loop {
                sleep 3600*2
                rebuildLx12sFromStratch()
            }
        }
    end

    def cacheTimeInSeconds()
        nil # we have a thread, see initialize(), that recomputes the structure every 2 hours
    end

    def lx12sInOrderForDisplay()
        @lx12s
            .select{|lx12| !lx12["priority"].nil? }
            .map{|lx12|
                lx12["item"] = lx12["item"].clone
                lx12
            }
            .sort{|l1, l2| l1["priority"] <=> l2["priority"] }
            .reverse
            .select{|lx12| 
                item = lx12["item"]
                DoNotShowUntil::isVisible(item["uuid"]) or NxBallsService::isPresent(item["uuid"])
            }
            .select{|lx12| 
                item = lx12["item"]
                InternetStatus::itemShouldShow(item["uuid"]) or NxBallsService::isPresent(item["uuid"])
            }
    end

    def rebuildLx12sFromStratch() # Array[Lx12]
        items = [
            JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`),
            Anniversaries::listingItems(),
            Waves::items(),
            NxTodos::items()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }

        @lx12s = items
            .map{|item|
                {
                    "item"     => item,
                    "priority" => PolyFunctions::listingPriorityOrNull(item),
                    "announce" => PolyFunctions::toString(item)
                }
            }
            .select{|packet| !packet["priority"].nil? }
            .sort{|p1, p2| p1["priority"] <=> p2["priority"] }
            .reverse
            .first(100)
        XCacheValuesWithExpiry::set("968dceb4-a0a9-4ffa-9b17-9b74a34e6bd9", @lx12s, cacheTimeInSeconds())
    end

    def mutateLx12sToRemoveItemByUUID(objectuuid)
        @lx12s = @lx12s.select{|lx12| lx12["item"]["uuid"] != objectuuid }
        XCacheValuesWithExpiry::set("968dceb4-a0a9-4ffa-9b17-9b74a34e6bd9", @lx12s, cacheTimeInSeconds())
    end

    def mutateLx12sToAddItemByUUIDFailSilently(objectuuid)
        item = Items::getItemOrNull(objectuuid)
        return if item.nil?
        begin
            @lx12s << {
                "item"     => item,
                "priority" => PolyFunctions::listingPriorityOrNull(item),
                "announce" => PolyFunctions::toString(item)
            }
            XCacheValuesWithExpiry::set("968dceb4-a0a9-4ffa-9b17-9b74a34e6bd9", @lx12s, cacheTimeInSeconds())
        rescue
            # In the process of building a NxTodo, we are going to run this at every mutation
            # meaning everytime a new attribute is set.
            # There will be a time where ItemsEventsLog::getProtoItemOrNull(objectuuid) will return someting
            # as well as Items::getItemOrNull(objectuuid), but the 
            # nx11e attribute will not have yet been set, resulting in PolyFunctions::listingPriorityOrNull(item) returning an error
        end
    end

    def mutateLx12sCycleItemByUUID(objectuuid)
        mutateLx12sToRemoveItemByUUID(objectuuid)
        mutateLx12sToAddItemByUUIDFailSilently(objectuuid)
        XCacheValuesWithExpiry::set("968dceb4-a0a9-4ffa-9b17-9b74a34e6bd9", @lx12s, cacheTimeInSeconds())
    end

    def processEvent(event)

        if event["mikuType"] == "(do not show until has been updated)" then
            #
        end

        if event["mikuType"] == "NxBankEvent" then
            bankaccount = event["setuuid"]
            Nx11EGroupsUtils::bankaccountToItems(bankaccount)
                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                .first(10)
                .each{|item|
                    mutateLx12sCycleItemByUUID(item["uuid"])
                }
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            # 
        end

        if event["mikuType"] == "bank-account-done-today" then
            bankaccount = event["bankaccount"]
            Nx11EGroupsUtils::bankaccountToItems(bankaccount)
                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                .first(10)
                .each{|item|
                    mutateLx12sCycleItemByUUID(item["uuid"])
                }
        end

        if event["mikuType"] == "NxDeleted" then
            objectuuid = event["objectuuid"]
            mutateLx12sToRemoveItemByUUID(objectuuid)
        end

        if event["mikuType"] == "NetworkLinks" then
            #
        end

        if event["mikuType"] == "XCacheUpdate" then
            #
        end

        if event["mikuType"] == "XCacheFlag" then
            #
        end

        if event["mikuType"] == "NetworkArrows" then
            #
        end

        if event["mikuType"] == "AttributeUpdate.v2" then
            # This is particluarly useful to capture newly created high priority objects
            # (One of the motivation for CatalystAlfred wasn't only to speed things up, but to immedately capture across the commsline a NxTodo hot)
            objectuuid = event["objectuuid"]
            mutateLx12sCycleItemByUUID(objectuuid)
        end

        if event["mikuType"] == "(object has been touched)" then
            objectuuid = event["objectuuid"]
            mutateLx12sCycleItemByUUID(objectuuid)
        end
    end

    def mutateAfterBankAccountUpdate(bankaccount)
        Nx11EGroupsUtils::bankaccountToItems(bankaccount).each{|item|
            mutateLx12sCycleItemByUUID(item["uuid"])
        }
    end
end

class CatalystListing

    # CatalystListing::listingCommands()
    def self.listingCommands()
        [
            ".. | <datecode> | <n> | start (<n>) | stop (<n>) | access (<n>) | description (<n>) | name (<n>) | datetime (<n>) | nx113 (<n>) | engine (<n>) | landing (<n>) | pause (<n>) | pursue (<n>) | do not show until <n> | redate (<n>) | done (<n>) | Ax39 done for today | edit (<n>) | transmute (<n>) | time * * | expose (<n>) | destroy",
            "update start date (<n>)",
            "wave | anniversary | hot | today | ondate | todo",
            "anniversaries | ondates | todos | waves | groups",
            "require internet",
            "search | nyx | speed | nxballs | rebuild",
        ].join("\n")
    end

    # CatalystListing::listingCommandInterpreter(input, store)
    def self.listingCommandInterpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                PolyActions::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if input == ".." then
            item = store.getDefault()
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match("access", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("access *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("anniversary", input) then
            Anniversaries::issueNewAnniversaryOrNullInteractively()
            return
        end

        if Interpreting::match("anniversaries", input) then
            Anniversaries::anniversariesDive()
            return
        end

        if input == "Ax39 done for today" then
            item = store.getDefault()
            return if item.nil?

            if item["mikuType"] != "NxTodo" then
                puts "Only a NxTodo can be target for `Ax39 done for today`"
                LucilleCore::pressEnterToContinue()
                return
            end

            nx11e = item["nx11e"]

            if nx11e["type"] != "Ax39Group" and nx11e["type"] != "Ax39Engine" then
                puts "Only NxTodos with Ax39 drivers can be target for `Ax39 done for today`"
                LucilleCore::pressEnterToContinue()
                return
            end

            if nx11e["type"] == "Ax39Group" then
                bankaccount = nx11e["group"]["account"]
                BankAccountDoneForToday::setDoneToday(bankaccount)
                $CatalystAlfred1.mutateAfterBankAccountUpdate(bankaccount)
                return
            end

            if nx11e["type"] == "Ax39Engine" then
                BankAccountDoneForToday::setDoneToday(nx11e["itemuuid"])
                $CatalystAlfred1.mutateLx12sCycleItemByUUID(item["uuid"])
                return
            end
            
            return
        end

        if Interpreting::match("destroy", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::destroyWithPrompt(item)
            return
        end

        if Interpreting::match("destroy *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::destroyWithPrompt(item)
            return
        end

        if Interpreting::match("datetime", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::editDatetime(item)
            return
        end

        if Interpreting::match("datetime *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::editDatetime(item)
            return
        end

        if Interpreting::match("description", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::editDescription(item)
            return
        end

        if Interpreting::match("description *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::editDescription(item)
            return
        end

        if Interpreting::match("done", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("done *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("edit", input) then
            item = store.getDefault()
            return if item.nil?
            PolyFunctions::edit(item)
            return
        end

        if Interpreting::match("edit *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyFunctions::edit(item)
            return
        end

        if Interpreting::match("engine", input) then
            item = store.getDefault()
            return if item.nil?
            Nx11E::interactivelySetANewEngineForItemOrNothing(item)
            return
        end

        if Interpreting::match("engine *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            Nx11E::interactivelySetANewEngineForItemOrNothing(item)
            return
        end

        if Interpreting::match("exit", input) then
            exit
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            if item["mikuType"] == "NxBall.v2" then
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "PolyFunctions::listingPriorityOrNull(item): #{PolyFunctions::listingPriorityOrNull(item)}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
            if item["mikuType"] == "NxBall.v2" then
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "PolyFunctions::listingPriorityOrNull(item): #{PolyFunctions::listingPriorityOrNull(item)}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("groups", input) then
            Nx11EGroupsUtils::groupsDive()
            return
        end

        if Interpreting::match("hot", input) then
            description = LucilleCore::askQuestionAnswerAsString("hot: ")
            item = NxTodos::interactivelyCreateNewHot(description)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("internet off", input) then
            InternetStatus::setInternetOff()
            return
        end

        if Interpreting::match("internet on", input) then
            InternetStatus::setInternetOn()
            return
        end

        if Interpreting::match("landing", input) then
            PolyPrograms::itemLanding(store.getDefault())
            return
        end

        if Interpreting::match("landing *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyPrograms::itemLanding(item)
            return
        end

        if Interpreting::match("nx113", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::setNx113(item)
            return
        end

        if Interpreting::match("nx113 *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::setNx113(item)
            return
        end

        if Interpreting::match("nyx", input) then
            Nyx::program()
            return
        end

        if Interpreting::match("nxballs", input) then
            puts JSON.pretty_generate(NxBallsIO::nxballs())
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxTodos::interactivelyCreateNewOndateOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            NxTodos::diveOndates()
            return
        end

        if Interpreting::match("pause", input) then
            item = store.getDefault()
            return if item.nil?
            NxBallsService::pause(item["uuid"])
            return
        end

        if Interpreting::match("pause *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBallsService::pause(item["uuid"])
            return
        end

        if Interpreting::match("pursue", input) then
            item = store.getDefault()
            return if item.nil?
            NxBallsService::pursue(item["uuid"])
            return
        end

        if Interpreting::match("pursue *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "pursuing: #{JSON.pretty_generate(item)}"
            NxBallsService::pursue(item["uuid"])
            return
        end

        if Interpreting::match("do not show until *", input) then
            _, _, _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
            return if datecode == ""
            unixtime = CommonUtils::codeToUnixtimeOrNull(datecode.gsub(" ", ""))
            return if unixtime.nil?
            PolyActions::stop(item)
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("require internet", input) then
            item = store.getDefault()
            return if item.nil?
            InternetStatus::markIdAsRequiringInternet(item["uuid"])
            return
        end

        if Interpreting::match("rebuild", input) then
            t1 = Time.new.to_f
            $CatalystAlfred1.rebuildLx12sFromStratch()
            t2 = Time.new.to_f
            puts "Completed in #{(t2-t1).round(2)} seconds"
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("redate", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::redate(item)
            return
        end

        if Interpreting::match("redate *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::redate(item)
            return
        end

        if Interpreting::match("search", input) then
            Search::navigation()
            return
        end

        if Interpreting::match("start", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("stop", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::stop(item)
            return
        end

        if Interpreting::match("time * *", input) then
            _, ordinal, timeInHours = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "Adding #{timeInHours.to_f} hours to #{PolyFunctions::toString(item).green}"
            Bank::put(item["uuid"], timeInHours.to_f*3600)
            return
        end

        if Interpreting::match("today", input) then
            NxTodos::interactivelyCreateNewTodayOrNull()
            return
        end

        if Interpreting::match("todo", input) then
            item = NxTodos::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input == "transmute" then
            item = store.getDefault()
            return if item.nil?
            PolyActions::transmute(item)
            return
        end

        if input == "transmute *" then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::transmute(item)
            return
        end

        if Interpreting::match("update start date", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::editStartDate(item)
        end

        if Interpreting::match("update start date *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::editStartDate(item)
            return
        end

        if input == "wave" then
            Waves::issueNewWaveInteractivelyOrNull()
            return
        end

        if input == "waves" then
            Waves::dive()
            return
        end

        if Interpreting::match("speed", input) then

            tests = [
                {
                    "name" => "source code trace generation",
                    "lambda" => lambda { CommonUtils::generalCodeTrace() }
                },
                {
                    "name" => "fitness lookup",
                    "lambda" => lambda { JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`) }
                },
                {
                    "name" => "Anniversaries::listingItems()",
                    "lambda" => lambda { Anniversaries::listingItems() }
                },
                {
                    "name" => "The99Percent::getCurrentCount()",
                    "lambda" => lambda { The99Percent::getCurrentCount() }
                },
            ]

            # dry run to initialise things
            tests
                .each{|test|
                    test["lambda"].call()
                }

            padding = tests.map{|test| test["name"].size }.max

            results = tests
                        .map{|test|
                            puts "running: #{test["name"]}"
                            t1 = Time.new.to_f
                            (1..3).each{ test["lambda"].call() }
                            t2 = Time.new.to_f
                            {
                                "name" => test["name"],
                                "runtime" => (t2 - t1).to_f/3
                            }
                        }
                        .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                        .reverse

            puts ""
            results
                .each{|result|
                    puts "- #{result["name"].ljust(padding)} : #{"%6.3f" % result["runtime"]}"
                }

            LucilleCore::pressEnterToContinue()
            return
        end
    end

    # CatalystListing::displayListing()
    def self.displayListing()

        system("clear")

        vspaceleft = CommonUtils::screenHeight() - 4

        vspaceleft =  vspaceleft - CommonUtils::verticalSize(CatalystListing::listingCommands())

        if Config::get("instanceId") == "Lucille20-pascal" then
            reference = The99Percent::getReferenceOrNull()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
            puts ""
            puts line
            vspaceleft = vspaceleft - 2
            if ratio < 0.99 then
                The99Percent::issueNewReferenceOrNull()
            end
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        packets = $CatalystGroupMonitor1.getLx13sForDisplay()
        if packets.size > 0 then
            puts ""
            puts "Nx53 (below completion 1):".yellow
            vspaceleft = vspaceleft - 2
            packets
                .each{|packet|
                    puts "    - #{packet["name"]} (#{packet["cr"].round(2)})".yellow
                    vspaceleft = vspaceleft - 1
                }
        end

        nxballs = NxBallsIO::nxballs()
        if nxballs.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            nxballs
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
                .each{|nxball|
                    store.register(nxball, false)
                    line = "#{store.prefixString()} [NxBall] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                    puts line.green
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        puts ""
        vspaceleft = vspaceleft - 1

        $CatalystAlfred1.lx12sInOrderForDisplay()
            .each{|lx12|
                break if vspaceleft <= 0
                item = lx12["item"]
                store.register(item, true)
                line = "#{store.prefixString()} #{lx12["announce"]}"
                if NxBallsService::isPresent(item["uuid"]) then
                    line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                end
                puts line
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }

        puts ""
        puts CatalystListing::listingCommands().yellow
        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")
        return if input == ""
        CatalystListing::listingCommandInterpreter(input, store)
    end

    # CatalystListing::program()
    def self.program()

        initialCodeTrace = CommonUtils::generalCodeTrace()

        SystemEvents::processCommsLine(true)

        loop {

            #puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            $commline_semaphore.synchronize {
                SystemEvents::processCommsLine(true)
            }

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Desktop/NxTodos")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTodos::issueUsingLocation(location)
                    puts "Picked up from NxTodos: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            CatalystListing::displayListing()
        }
    end
end