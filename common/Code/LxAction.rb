
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

            if !NxBallsService::isRunning(object["uuid"]) then
                NxBallsService::issue(object["uuid"], object["announce"] ? object["announce"] : "(object: #{object["uuid"]})" , [object["uuid"]])
            end

            LxAction::action("access", object)

            if object["mikuType"] == "NS16:TxDated" and object["announce"].include?("(vienna)") then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ", true) then
                    item = object["TxDated"]
                    TxDateds::destroy(item["uuid"])
                    NxBallsService::close(item["uuid"], true)
                end
            end

            if object["mikuType"] == "NS16:TxTodo" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ") then
                    item = object["TxTodo"]
                    TxTodos::destroy(item["uuid"])
                    NxBallsService::close(item["uuid"], true)
                end
            end

            return
        end

        if command == "[]" then
            Topping::applyTransformation(UniverseStorage::getUniverseOrNull())
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

            if object["lambda"] then
                object["lambda"].call()
                return
            end

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

            if object["mikuType"] == "NS16:TxProject" then
                item = object["TxProject"]
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

            Mercury::postValue("b6156390-059d-446e-ad51-adfc9f91abf1", object["uuid"])

            # If the object was running, then we stop it
            if NxBallsService::isRunning(object["uuid"]) then
                 NxBallsService::close(object["uuid"], true)
            end

            if object["mikuType"] == "ADE4F121" then
                # That's the rstream
                return
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
            if object["mikuType"] == "NS16:TxProject" then
                item = object["TxProject"]
                NxBallsService::close(item["uuid"], true)
                XCache::setFlagTrue("915b-09a30622d2b9:FyreIsDoneForToday:#{CommonUtils::today()}:#{item["uuid"]}")
                return
            end
            if object["mikuType"] == "NS16:TxInbox2" then
                item = object["item"]
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of inbox item '#{item["description"].green}' ? ", true) then
                    TxTodos::destroy(item["uuid"])
                end
                return
            end
            if object["mikuType"] == "NS16:TxTodo" then
                item = object["TxTodo"]
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of todo '#{item["description"].green}' ? ", true) then
                    TxTodos::destroy(item["uuid"])
                end
                return
            end
            if object["mikuType"] == "NS16:Wave" then
                item = object["wave"]
                if LucilleCore::askQuestionAnswerAsBoolean("confirm done-ing '#{Waves::toString(item).green} ? '", true) then
                    Waves::performDone(item)
                end
                return
            end
        end

        if command == "project" then
            TxProjects::interactivelyCreateNewOrNull()
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

        if command == "projects" then
            TxProjects::dive()
            return
        end

        if command == "inbox" then
            
            # This function creates a TxInbox2 object that is going to be dropped into the Inbox folder. 
            # Catalyst will know how to pick them up properly and how to present them

            line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
            return if line == ""
            uuid = SecureRandom.uuid

            aionrootnhash = nil

            location = CommonUtils::interactivelySelectDesktopLocationOrNull() 
            if location then
                aionrootnhash = AionCore::commitLocationReturnHash(Fx12sElizabethV2.new(uuid), location)
            end

            item = {
                "uuid"          => uuid,
                "mikuType"      => "TxInbox2",
                "unixtime"      => Time.new.to_i,
                "line"          => line,
                "aionrootnhash" => aionrootnhash
            }

            puts JSON.pretty_generate(item)

            Librarian::commit(item)

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

            if object["mikuType"] == "NS16:TxProject" then
                nx70 = object["TxProject"]
                TxProjects::landing(nx70)
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

            if object["mikuType"] == "TxProject" then
                TxProjects::landing(object)
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
                datetime = (CommonUtils::interactivelySelectAUTCIso8601DateTimeOrNull() || Time.new.utc.iso8601)
                mx49["datetime"] = datetime
                Librarian::commit(mx49)
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

            if ns16["mikuType"] == "NS16:TxProject" then
                project = ns16["TxProject"]
                puts "Adding #{timeInHours} hours to #{project["uuid"]}"
                Bank::put(project["uuid"], timeInHours*3600)
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
            universe = UniverseStorage::getUniverseOrNull()
            nx50s =  TxTodos::itemsForUniverse(universe)
            if LucilleCore::askQuestionAnswerAsBoolean("limit ? ", true) then
                nx50s = nx50s.first(CommonUtils::screenHeight()-4)
            end
            loop {
                system("clear")
                nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", nx50s, lambda {|nx50| "#{TxTodos::toString(nx50)} (#{nx50["ordinal"]})" })
                return if nx50.nil?
                TxTodos::landing(nx50)
            }
            return
        end

        if command == "top" then
            Topping::top(UniverseStorage::getUniverseOrNull())
            return
        end

        if command == "transmute" then
            if object["mikuType"] == "NS16:TxDated" then
                mx49 = object["TxDated"]
                Transmutation::transmutation2(mx49, "TxDated")
                return
            end

            if object["mikuType"] == "NS16:TxProject" then
                nx70 = object["TxProject"]
                Transmutation::transmutation2(nx70, "TxProject")
                return
            end

            if object["mikuType"] == "NS16:TxTodo" then
                nx70 = object["TxTodo"]
                Transmutation::transmutation2(nx70, "TxTodo")
                return
            end
        end

        if command == "universe" then
            UniverseStorage::interactivelySetUniverse()
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