
class CentralDispatch

    # CentralDispatch::operator1(object, command)
    def self.operator1(object, command)

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
            Mercury::postValue("A4EC3B4B-NATHALIE-COLLECTION-REMOVE", object["uuid"])
        end

        if object["NS198"] == "ns16:wave1" and command == ".." then
            Waves::run(object["wave"])
        end

        if object["NS198"] == "ns16:wave1" and command == "landing" then
            Waves::landing(object["wave"])
        end

        if object["NS198"] == "ns16:wave1" and command == "done" then
            Waves::performDone(object["wave"])
        end

        if object["NS198"] == "ns16:inbox1" and command == ".." then
            Inbox::run(object["location"])
        end

        if object["NS198"] == "ns16:Nx501" and command == ".." then
            Nx50s::run(object["Nx50"])
        end

        if object["NS198"] == "ns16:Nx501" and command == "done" then
            nx50 = object["Nx50"]
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx50s::toString(nx50)}' ? ", true) then
                Nx50s::complete(nx50)
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

        if object["NS198"] == "ns16:top1" and command == "done" then
            puts object["announce"]
            BTreeSets::destroy(nil, "213f801a-fd93-4839-a55b-8323520494bc", object["uuid"])
        end
    end

    # CentralDispatch::operator4(command)
    def self.operator4(command)

        if command == "eva" then
            Domain::setStoredDomainWithExpiry("(eva)", Time.new.to_i + 3600)
        end
        if command == "work" then
            Domain::setStoredDomainWithExpiry("(work)", Time.new.to_i + 3600)
        end
        if command == "jedi" then
            Domain::setStoredDomainWithExpiry("(jedi)", Time.new.to_i + 3600)
        end
        if command == "entertainment" then
            Domain::setStoredDomainWithExpiry("(entertainment)", Time.new.to_i + 3600)
        end
        if command == "nathalie" then
            KeyValueStore::destroy(nil, "6992dae8-5b15-4266-a2c2-920358fda286")
        end

        if command == "start" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return if description == ""
            domain = Domain::interactivelySelectDomain()
            domainBankAccount = Domain::domainToBankAccount(domain)
            NxBallsService::issue(SecureRandom.uuid, description, [domainBankAccount])
        end

        if command == "monitor" then
            nx50 = Nx50s::issueItemWithCategoryLambda(lambda{["Monitor"]})
            puts JSON.pretty_generate(nx50)
        end

        if command == "today" then
            nx50 = Nx50s::issueItemWithCategoryLambda(lambda{["Dated", Utils::today()]})
            puts JSON.pretty_generate(nx50)
        end

        if Interpreting::match("ondate", command) then
            nx50 = Nx50s::issueItemWithCategoryLambda(lambda{["Dated", Utils::interactivelySelectADateOrNull() || Utils::today()]})
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
            domain = Domain::interactivelySelectDomain()
            Waves::waves(domain)
        end

        if Interpreting::match("Nx50s", command) then
            nx50s = Nx50s::nx50s()
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

    # CentralDispatch::operator5(store, command)
    def self.operator5(store, command)

        if Interpreting::match("expose", command) then
            ns16 = store.getDefault()
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
            ns16 = store.getDefault()
            return if ns16.nil?
            InternetStatus::markIdAsRequiringInternet(ns16["uuid"])
        end
    end
end