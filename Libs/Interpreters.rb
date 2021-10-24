# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Interpreters

    # Interpreters::listingCommands()
    def self.listingCommands()
        ".. | <n> | <datecode> | hide <n> <datecode> | expose"
    end

    # Interpreters::listingInterpreter(store, command)
    def self.listingInterpreter(store, command)

        # The case <n> should hve already been captured by UIServices

        # The case [] should have already been caputred by UIServices

        if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
            ns16 = store.getDefault()
            return if ns16.nil? 
            DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
            puts "Hidden until: #{Time.at(unixtime).to_s}"
        end

        if Interpreting::match("hide * *", command) then
            _, ordinal, datecode = Interpreting::tokenizer(command)
            ordinal = ordinal.to_i
            ns16 = store.get(ordinal)
            return if ns16.nil?
            unixtime = Utils::codeToUnixtimeOrNull(datecode)
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
        end

        if Interpreting::match("expose", command) then
            ns16 = store.getDefault()
            return if ns16.nil? 
            puts JSON.pretty_generate(ns16)
            LucilleCore::pressEnterToContinue()
        end
    end

    # Interpreters::makersAndDiversCommands()
    def self.makersAndDiversCommands()
        "on | today | todo | float | wave | ondate | anniversary | Nx50 | calendar | waves | ondates | Nx50s | anniversaries | search | fsck | >> | nyx"
    end

    # Interpreters::makersCommands()
    def self.makersCommands()
        "on | today | todo | float | wave | ondate | anniversary | Nx50"
    end

    # Interpreters::diversCommands()
    def self.diversCommands()
        "calendar | waves | ondates | Nx50s | anniversaries | search | fsck | >> | nyx"
    end

    # Interpreters::makersAndDiversInterpreter(command)
    def self.makersAndDiversInterpreter(command)

        if command == "on" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            item = OnGoing::makeNewFromDescription(description)
            puts JSON.pretty_generate(item)
        end

        if command == "today" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            item = Today::makeNewFromDescription(description, true)
            puts JSON.pretty_generate(item)
        end

        if command == "todo" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = LucilleCore::timeStringL22()
            domain = Domain::interactivelySelectDomain()
            unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
            Nx50s::commitNx50ToDatabase({
                "uuid"        => uuid,
                "unixtime"    => unixtime,
                "description" => description,
                "coreDataId"  => nil,
                "domain"      => domain
            })
        end

        if Interpreting::match("float", command) then
            Floats::interactivelyCreateNewOrNull()
        end

        if Interpreting::match("wave", command) then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("ondate", command) then
            item = NxOnDate::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("Nx50", command) then
            item = Nx50s::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("anniversary", command) then
            item = Anniversaries::issueNewAnniversaryOrNullInteractively()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("ondates", command) then
            NxOnDate::main()
        end

        if Interpreting::match("anniversaries", command) then
            Anniversaries::anniversariesDive()
        end

        if Interpreting::match("calendar", command) then
            Calendar::main()
        end

        if Interpreting::match("waves", command) then
            domain = Domain::getCurrentDomain()
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

        if Interpreting::match(">>", command) then
            key = "4b23af4b-4536-44f6-a85a-d4e8cb320b30"
            Nx50s::nx50s().each{|nx50|

                next if KeyValueStore::flagIsTrue(nil, "#{key}:#{nx50["uuid"]}")
                next if nx50["domain"] != "(eva)" 

                nxball = NxBalls::makeNxBall([nx50["uuid"]])

                accessWithOptionToEdit = lambda{|uuid|
                    return if uuid.nil?
                    object = CoreDataUtils::getObjectOrNull(uuid)
                    if object["type"] == "text" then
                        puts object["text"]
                        return
                    end
                    if object["type"] == "url" then
                        Utils::openUrlUsingSafari(object["url"])
                    end
                    if object["type"] == "aion-point" then
                        AionCore::exportHashAtFolder(CoreDataElizabeth.new(), object["nhash"], "/Users/pascal/Desktop")
                    end
                }

                accessWithOptionToEdit.call(nx50["coreDataId"])

                command = LucilleCore::askQuestionAnswerAsString("[#{Nx50s::nx50sForDomain("(eva)").size}] #{Nx50s::toString(nx50).green} (done, landing, next, exit) : ")

                NxBalls::closeNxBall(nxball, false)

                if command == "done" then
                    Nx50s::complete(nx50)
                end

                if command == "landing" then
                    Nx50s::run(nx50)
                    KeyValueStore::setFlagTrue(nil, "#{key}:#{nx50["uuid"]}")
                end

                if command == "next" then
                    KeyValueStore::setFlagTrue(nil, "#{key}:#{nx50["uuid"]}")
                    next
                end

                if command == "exit" then
                    break
                end
            }
        end

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match("fsck", command) then
            Fsck::fsck()
        end

        if Interpreting::match("nyx", command) then
            system("/Users/pascal/Galaxy/Software/Nyx/nyx")
        end
    end
end
