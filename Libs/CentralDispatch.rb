
class CentralDispatch

    # CentralDispatch::closeAnyNxBallWithThisID(uuid)
    def self.closeAnyNxBallWithThisID(uuid)
        NxBallsService::close(uuid, true)
    end

    # CentralDispatch::operator1(object, command)
    def self.operator1(object, command)

        return if object.nil?

        # puts "CentralDispatch, object: #{object}, command: #{command}"

        if object["NS198"] == "NxBallDelegate1" and command == ".." then
            uuid = object["uuid"]

            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["close", "pursue", "pause"])
            if action == "close" then
                NxBallsService::close(uuid, true)
            end
            if action == "pursue" then
                NxBallsService::pursue(uuid)
            end
            if action == "pause" then
                NxBallsService::pause(uuid)
            end
        end

        if object["NS198"] == "ns16:fitness1" and command == ".." then
            system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
        end

        if object["NS198"] == "ns16:wave1" and command == ".." then
            Waves::run(object["wave"])
        end

        if object["NS198"] == "ns16:wave1" and command == "landing" then
            Waves::landing(object["wave"])
        end

        if object["NS198"] == "ns16:wave1" and command == "done" then
            Waves::performDone(object["wave"])
            CentralDispatch::closeAnyNxBallWithThisID(object["uuid"])
        end

        if object["NS198"] == "ns16:wave1" and command == ">entertainment" then
            wave = object["wave"]
            wave["listing"] = "ENTERTAINMENT"
            ObjectStore4::store(wave, Waves::setuuid())
            CentralDispatch::closeAnyNxBallWithThisID(object["uuid"])
        end

        if object["NS198"] == "ns16:inbox1" and command == ".." then
            Inbox::run(object["location"])
        end

        if object["NS198"] == "ns16:inbox1" and command == ">>" then
            Inbox::dispatch(object["location"])
        end

        if object["NS198"] == "ns16:Nx50" and command == ".." then
            Nx50s::run(object["Nx50"])
        end

        if object["NS198"] == "ns16:Nx50" and command == "redate" then
            nx50 = object["Nx50"]
            if nx50["category2"][0] == "Dated" then
                nx50["category2"][1] = (Utils::interactivelySelectADateOrNull() || Utils::today())
                AFewNx50s::commit(nx50)
            else
                puts "You can only redate a dated item"
                LucilleCore::pressEnterToContinue()
            end
        end

        if object["NS198"] == "ns16:Nx50" and command == "recategory" then
            nx50 = object["Nx50"]
            category2 = Nx50s::makeNewCategory2()
            nx50["category2"] = category2
            nx50["ordinal"] = Nx50s::interactivelyDecideNewOrdinal(listing, category2)
            AFewNx50s::commit(nx50)
        end

        if object["NS198"] == "ns16:Nx50" and command == "done" then
            nx50 = object["Nx50"]
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx50s::toString(nx50)}' ? ", true) then
                Nx50s::complete(nx50)
                CentralDispatch::closeAnyNxBallWithThisID(object["uuid"])
            end
        end

        if object["NS198"] == "ns16:anniversary1" and command == ".." then
            Anniversaries::run(object["anniversary"])
        end

        if object["NS198"] == "ns16:anniversary1" and command == "done" then
            anniversary = object["anniversary"]
            puts Anniversaries::toString(anniversary).green
            anniversary["lastCelebrationDate"] = Time.new.to_s[0, 10]
            Anniversaries::commitAnniversaryToDisk(anniversary)
        end

        if object["NS198"] == "ns16:calendar1" and command == ".." then
            Calendar::run(object["item"])
        end

        if object["NS198"] == "ns16:calendar1" and command == "done" then
            Calendar::moveToArchives(object["item"])
        end
    end

    # CentralDispatch::operator4(command)
    def self.operator4(command)

        if command == "start" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return if description == ""
            listing = Listings::interactivelySelectListing()
            account = Listings::listingToBankAccount(listing)
            NxBallsService::issue(SecureRandom.uuid, description, [account])
        end

        if command == "monitor" then
            nx50 = Nx50s::issueItemWithCategoryLambdaOrNull(lambda{["Monitor"]})
            return if nx50.nil?
            puts JSON.pretty_generate(nx50)
        end

        if command == "today" then
            nx50 = Nx50s::issueItemWithCategoryLambdaOrNull(lambda{["Dated", Utils::today()]})
            return if nx50.nil?
            puts JSON.pretty_generate(nx50)
        end

        if Interpreting::match("ondate", command) then
            nx50 = Nx50s::issueItemWithCategoryLambdaOrNull(lambda{["Dated", Utils::interactivelySelectADateOrNull() || Utils::today()]})
            return if nx50.nil?
            puts JSON.pretty_generate(nx50)
        end

        if command == "todo" then
            item = Nx50s::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("wave", command) then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("anniversary", command) then
            item = Anniversaries::issueNewAnniversaryOrNullInteractively()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("anniversaries", command) then
            Anniversaries::anniversariesDive()
        end

        if Interpreting::match("calendar", command) then
            Calendar::main()
        end

        if Interpreting::match("waves", command) then
            Waves::waves()
        end

        if Interpreting::match("Nx50s", command) then
            nx50s = AFewNx50s::getSet()
            if LucilleCore::askQuestionAnswerAsBoolean("limit ? ", true) then
                nx50s = nx50s.first(Utils::screenHeight()-1)
            end
            loop {
                nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", nx50s, lambda {|nx50| Nx50s::toString(nx50) })
                return if nx50.nil?
                Nx50s::run(nx50)
            }
        end

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match("nyx", command) then
            system("/Users/pascal/Galaxy/Software/Nyx/nyx")
        end
    end

    # CentralDispatch::operator5(ns16, command)
    def self.operator5(ns16, command)

        if Interpreting::match("expose", command) then
            return if ns16.nil? 
            puts JSON.pretty_generate(ns16)
            LucilleCore::pressEnterToContinue()
        end

        if Interpreting::match("internet on", command) then
            InternetStatus::setInternetOn()
        end

        if Interpreting::match("internet off", command) then
            InternetStatus::setInternetOff()
        end

        if Interpreting::match("require internet", command) then
            return if ns16.nil?
            InternetStatus::markIdAsRequiringInternet(ns16["uuid"])
        end
    end
end
