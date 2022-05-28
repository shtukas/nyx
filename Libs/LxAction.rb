
class LxAction

    # LxAction::action(command, object or nil)
    def self.action(command, object)

        # All objects sent to this are expected to have an mikyType attribute

        return if command.nil?

        if object and object["mikuType"].nil? then
            puts "Objects sent to LxAction::action if not null should have a mikuType attribute."
            puts "Got:"
            puts "command: #{command}"
            puts "object:"
            puts JSON.pretty_generate(object)
            puts "Aborting."
            exit
        end

        if command == ".." then

            if object["mikuType"] == "NS16:TxDated" and object["announce"].include?("(vienna)") then
                LxAction::action("access", object)
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ", true) then
                    item = object["TxDated"]
                    TxDateds::destroy(item["uuid"])
                end
                return
            end

            if object["mikuType"] == "NS16:TxFyre" then
                if !NxBallsService::isRunning(object["uuid"]) then
                    LxAction::action("start", object)
                end
                LxAction::action("access", object)
                if NxBallsService::isRunning(object["uuid"]) then
                    if !LucilleCore::askQuestionAnswerAsBoolean("continue running ? ") then
                        LxAction::action("stop", object)
                    end
                end
                return
            end

            if object["mikuType"] == "NS16:TxTodo" then
                if !NxBallsService::isRunning(object["uuid"]) then
                    LxAction::action("start", object)
                end
                LxAction::action("access", object)
                if NxBallsService::isRunning(object["uuid"]) then
                    if LucilleCore::askQuestionAnswerAsBoolean("continue running ? ") then
                        # Nothing else to do, we return
                    else
                        LxAction::action("stop", object)
                        if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ") then
                            item = object["TxTodo"]
                            TxTodos::destroy(item["uuid"])
                        end
                    end
                end
                return
            end

            LxAction::action("access", object)
            return
        end

        if command == "[]" then
            Topping::applyTransformation(ActiveUniverse::getUniverseOrNull())
            return
        end

        if command == ">nyx" then
            if object["mikuType"] == "NS16:TxTodo" then
                item = object["TxTodo"]
                Transmutation::transmutation1(item, "TxTodo", "Nx100")
                return
            end
        end

        if command == ">todo" then
            if object["mikuType"] == "NS16:TxDated" then
                item = object["TxDated"]
                Transmutation::transmutation1(item, "TxDated", "TxTodo")
                return
            end
        end

        if command == "access" then

            if object["mikuType"] == "NS16:Anniversary1" then
                Anniversaries::access(object["anniversary"])
                return
            end

            if object["mikuType"] == "NS16:fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
                return
            end

            if object["mikuType"] == "NS16:TxInbox2" then
                Inbox::landingInbox2(object["item"])
                return
            end

            if object["mikuType"] == "NS16:TxDated" then
                item = object["TxDated"]
                EditionDesk::accessItem(item)
                return
            end

            if object["mikuType"] == "NS16:TxFyre" then
                item = object["TxFyre"]
                EditionDesk::accessItem(item)
                return
            end

            if object["mikuType"] == "NS16:TxFloat" then
                item = object["TxFloat"]
                EditionDesk::accessItem(item)
                return
            end

            if object["mikuType"] == "NS16:TxTodo" then
                item = object["TxTodo"]
                EditionDesk::accessItem(item)
                return
            end

            if object["mikuType"] == "NS16:Wave" then
                Waves::access(object["wave"])
                return
            end

            if object["mikuType"] == "TxTodo" then
                EditionDesk::accessItem(object)
                return
            end
        end

        if command == "anniversary" then
            item = Anniversaries::issueNewAnniversaryOrNullInteractively()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if command == "anniversaries" then
            Anniversaries::anniversariesDive()
            return
        end

        if command == "done" then

            Mercury::postValue("b6156390-059d-446e-ad51-adfc9f91abf1", object["uuid"]) # done deletion for ListingDataDriver

            # If the object was running, then we stop it
            if NxBallsService::isRunning(object["uuid"]) then
                LxAction::action("stop", object)
            end
            if object["mikuType"] == "NxBallNS16Delegate1" then
                NxBallsService::close(object["uuid"], true)
                return
            end
            if object["mikuType"] == "NS16:Anniversary1" then
                anniversary = object["anniversary"]
                Anniversaries::done(anniversary)
                return
            end
            if object["mikuType"] == "NS16:TxDated" then
                item = object["TxDated"]
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of dated '#{item["description"].green}' ? ", true) then
                    TxDateds::destroy(item["uuid"])
                end
                return
            end
            if object["mikuType"] == "NS16:TxFyre" then
                item = object["TxFyre"]
                NxBallsService::close(item["uuid"], true)
                XCache::setFlagTrue("905b-09a30622d2b9:FyreIsDoneForToday:#{DidactUtils::today()}:#{item["uuid"]}")
                return
            end
            if object["mikuType"] == "NS16:TxInbox2" then
                item = object["item"]
                LocalObjectsStore::logicaldelete(item["uuid"])
                return
            end
            if object["mikuType"] == "NS16:TxTodo" then
                item = object["TxTodo"]
                if NxBallsService::isRunning(item["uuid"]) then
                    action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["stop running NxBall", "destroy item"])
                    return if action.nil?
                    if action == "stop running NxBall" then
                        NxBallsService::close(item["uuid"], true)
                        return
                    end
                    if action == "destroy item" then
                        # We go through the next section
                    end
                end
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of todo '#{item["description"].green}' ? ", true) then
                    TxTodos::destroy(item["uuid"])
                end
                return
            end
            if object["mikuType"] == "NS16:Wave" then
                item = object["wave"]
                return if !LucilleCore::askQuestionAnswerAsBoolean("confirm done-ing '#{Waves::toString(item).green} ? '", true)
                Waves::performDone(item)
                return
            end
        end

        if command == "fyre" then
            TxFyres::interactivelyCreateNewOrNull()
            return
        end

        if command == "expose" then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "exit" then
            exit
        end

        if command == "float" then
            TxFloats::interactivelyCreateNewOrNull()
            return
        end

        if command == "fyres" then
            TxFyres::dive()
            return
        end

        if command == "inbox" then
            
            # This function creates a TxInbox2 object that is going to be dropped into the Inbox folder. 
            # Catalyst will know how to pick them up properly and how to present them

            line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
            return if line == ""
            aionrootnhash = nil
            location = DidactUtils::interactivelySelectDesktopLocationOrNull() 
            if location then
                aionrootnhash = AionCore::commitLocationReturnHash(EnergyGridElizabeth.new(), location)
            end

            item = {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxInbox2",
                "unixtime"      => Time.new.to_i,
                "line"          => line,
                "aionrootnhash" => aionrootnhash
            }

            puts JSON.pretty_generate(item)

            LocalObjectsStore::commit(item)

            if location then
                LucilleCore::removeFileSystemLocation(location)
            end

            return
        end

        if command == "internet on" then
            InternetStatus::setInternetOn()
            return
        end

        if command == "internet off" then
            InternetStatus::setInternetOff()
            return
        end

        if command == "landing" then

            if object["mikuType"] == "Ax1Text" then
                Ax1Text::landing(object)
                return
            end

            if object["mikuType"] == "NS16:Anniversary1" then
                Anniversaries::landing(object["anniversary"])
                return
            end

            if object["mikuType"] == "NS16:fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
                return
            end

            if object["mikuType"] == "NS16:TxDated" then
                mx49 = object["TxDated"]
                TxDateds::landing(mx49)
                return
            end

            if object["mikuType"] == "NS16:TxFyre" then
                nx70 = object["TxFyre"]
                TxFyres::landing(nx70)
                return
            end

            if object["mikuType"] == "NS16:TxFloat" then
                TxFloats::landing(object["TxFloat"])
                return
            end

            if object["mikuType"] == "NS16:TxTodo" then
                TxTodos::landing(object["TxTodo"])
                return
            end

            if object["mikuType"] == "NS16:Wave" then
                Waves::landing(object["wave"])
                return
            end

            if object["mikuType"] == "Nx100" then
                Nx100s::landing(object)
                return
            end

            if object["mikuType"] == "TxAttachment" then
                TxAttachments::landing(object)
                return
            end

            if object["mikuType"] == "TxFyre" then
                TxFyres::landing(object)
                return
            end

            if object["mikuType"] == "TxFloat" then
                TxFloats::landing(object)
                return
            end

            if object["mikuType"] == "TxTodo" then
                TxTodos::landing(object)
                return
            end

            if object["mikuType"] == "TxAttachment" then
                TxAttachments::landing(object)
                return
            end

            if object["mikuType"] == "TxOS01" then
                o = object["payload"]
                o["isSnapshot"] = true
                LxAction::action("landing", o)
                return
            end

            if object["mikuType"] == "Wave" then
                Waves::landing(object)
                return
            end
        end

        if command == "nyx" then
            puts "(info: 4B14BAB4-7414-4090-982D-29C218EB5408) command nyx: to be written, call the executable"
            exit
            return
        end

        if command == "ondate" then
            item = TxDateds::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if command == "ondates" then
            TxDateds::dive()
            return
        end

        if command == "pause" then
            NxBallsService::pause(object["uuid"])
            return
        end

        if command == "pursue" then
            ns16 = object
            NxBallsService::pursue(ns16["uuid"])
            return
        end

        if command == "redate" then
            ns16 = object
            if ns16["mikuType"] == "NS16:TxDated" then
                mx49 = ns16["TxDated"]
                datetime = (DidactUtils::interactivelySelectAUTCIso8601DateTimeOrNull() || Time.new.utc.iso8601)
                mx49["datetime"] = datetime
                LocalObjectsStore::commit(mx49)
                return
            end
        end

        if command == "require internet" then
            ns16 = object
            InternetStatus::markIdAsRequiringInternet(ns16["uuid"])
            return
        end

        if command == "start something" then
            uuid = SecureRandom.uuid
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            universe = Multiverse::interactivelySelectUniverse()
            NxBallsService::issue(uuid, description, [])
            return
        end

        if command == "search" then
            Search::classicInterface()
            return
        end

        if command == "start" then
            ns16 = object
            NxBallsService::issue(ns16["uuid"], ns16["announce"], [ns16["uuid"]])
            return
        end

        if command == "stop" then
            NxBallsService::close(object["uuid"], true)
            return
        end

        if command == "time" and object["mikuType"] == "TimeInstructionAdd" then
            ns16 = object["ns16"]
            timeInHours = object["timeInHours"]

            if ns16["mikuType"] == "NS16:TxTodo" then
                todo = ns16["TxTodo"]
                puts "Adding #{timeInHours} hours to #{todo["uuid"]}"
                Bank::put(todo["uuid"], timeInHours*3600)
                return
            end

            if ns16["mikuType"] == "NS16:TxFyre" then
                fyre = ns16["TxFyre"]
                puts "Adding #{timeInHours} hours to #{fyre["uuid"]}"
                Bank::put(fyre["uuid"], timeInHours*3600)
                return
            end

            if ns16["mikuType"] == "Tx0930" then
                puts "Adding #{timeInHours} hours to work global commitment"
                Bank::put(ns16["uuid"], timeInHours*3600)
                return
            end
        end

        if command == "today" then
            mx49 = TxDateds::interactivelyCreateNewTodayOrNull()
            return if mx49.nil?
            puts JSON.pretty_generate(mx49)
            return
        end

        if command == "todo" then
            item = TxTodos::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if command == "rstream" then
            TxTodos::rstream()
            return
        end

        if command == "todos" then
            nx50s = TxTodos::items()
            if LucilleCore::askQuestionAnswerAsBoolean("limit ? ", true) then
                nx50s = nx50s.first(DidactUtils::screenHeight()-2)
            end
            loop {
                nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", nx50s, lambda {|nx50| TxTodos::toString(nx50) })
                return if nx50.nil?
                TxTodos::landing(nx50)
            }
            return
        end

        if command == "top" then
            Topping::top(ActiveUniverse::getUniverseOrNull())
            return
        end

        if command == "transmute" then
            if object["mikuType"] == "NS16:TxDated" then
                mx49 = object["TxDated"]
                Transmutation::transmutation2(mx49, "TxDated")
                return
            end

            if object["mikuType"] == "NS16:TxFyre" then
                nx70 = object["TxFyre"]
                Transmutation::transmutation2(nx70, "TxFyre")
                return
            end

            if object["mikuType"] == "NS16:TxTodo" then
                nx70 = object["TxTodo"]
                Transmutation::transmutation2(nx70, "TxTodo")
                return
            end
        end

        if command == "universe" then
            ActiveUniverse::interactivelySetUniverse()
            return
        end

        if command == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if command == "waves" then
            Waves::waves()
            return
        end

        puts "I do not know how to do action (command: #{command}, object: #{JSON.pretty_generate(object)})"
        LucilleCore::pressEnterToContinue()
    end
end