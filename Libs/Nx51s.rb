# encoding: UTF-8

class Nx51ItemCircuitBreaker

    # Nx51ItemCircuitBreaker::getRTUpperBoundOrNull(uuid)
    def self.getRTUpperBoundOrNull(uuid)
        value = KeyValueStore::getOrNull(nil, "39ce201c-f757-4a39-b1b6-90e292ea77b6:#{uuid}")
        return nil if value.nil?
        value.to_f
    end

    # Nx51ItemCircuitBreaker::getRTUpperBoundOrDefault(uuid, default)
    def self.getRTUpperBoundOrDefault(uuid, default)
        Nx51ItemCircuitBreaker::getRTUpperBoundOrNull(uuid) || default
    end

    # Nx51ItemCircuitBreaker::set(uuid, value)
    def self.set(uuid, value)
        KeyValueStore::set(nil, "39ce201c-f757-4a39-b1b6-90e292ea77b6:#{uuid}", value)
    end

    # Nx51ItemCircuitBreaker::interactivelySetValue(nx51)
    def self.interactivelySetValue(nx51)
        value = LucilleCore::askQuestionAnswerAsString("RT upper bound for #{Nx51s::toString(nx51)} (empty for abort) : ")
        return if value == ""
        value = value.to_f
        Nx51ItemCircuitBreaker::set(nx51["uuid"], value)
    end

    # Nx51ItemCircuitBreaker::isWithinBounds(ns16)
    def self.isWithinBounds(ns16)
        ns16["rt"] < Nx51ItemCircuitBreaker::getRTUpperBoundOrDefault(ns16["uuid"], 1)
    end

    # Nx51ItemCircuitBreaker::upperStr(nx51)
    def self.upperStr(nx51)
        bound = Nx51ItemCircuitBreaker::getRTUpperBoundOrDefault(nx51["uuid"], 1)
        "(#{"%5.2f" % bound})"
    end

end

class Nx51s

    # Nx51s::databaseItemToNx51(item)
    def self.databaseItemToNx51(item)
        item["contentType"]    = item["payload1"]
        item["contentPayload"] = item["payload2"]
        item["ordinal"]        = item["payload3"].to_f # 😬
        item
    end

    # Nx51s::nx51s()
    def self.nx51s()
        CatalystDatabase::getItemsByCatalystType("Nx51").map{|item|
            Nx51s::databaseItemToNx51(item)
        }
    end

    # Nx51s::nx51sPerOrdinal()
    def self.nx51sPerOrdinal()
        Nx51s::nx51s()
            .sort{|n1, n2| n1["ordinal"]<=>n2["ordinal"] }
    end

    # Nx51s::commitNx51ToDisk(nx51)
    def self.commitNx51ToDisk(nx51)
        uuid         = nx51["uuid"]
        unixtime     = nx51["unixtime"]
        description  = nx51["description"]
        catalystType = "Nx51"
        payload1     = nx51["contentType"]
        payload2     = nx51["contentPayload"]
        payload3     = nx51["ordinal"]
        payload4     = nil 
        payload5     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, payload4, payload5)
    end

    # Nx51s::getNx51ByUUIDOrNull(uuid)
    def self.getNx51ByUUIDOrNull(uuid)
        item = CatalystDatabase::getItemByUUIDOrNull(uuid)
        return nil if item.nil?
        Nx51s::databaseItemToNx51(item)
    end

    # Nx51s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid

        unixtime     = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        coordinates  = Axion::interactivelyIssueNewCoordinatesOrNull()

        ordinal      = Nx51s::decideOrdinal(description)

        catalystType = "Nx51"
        payload1     = coordinates ? coordinates["contentType"] : nil
        payload2     = coordinates ? coordinates["contentPayload"] : nil
        payload3     = ordinal
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        Nx51s::getNx51ByUUIDOrNull(uuid)
    end

    # Nx51s::minusOneUnixtime()
    def self.minusOneUnixtime()
        items = Nx51s::nx51s()
        return Time.new.to_i if items.empty?
        items.map{|item| item["unixtime"] }.min - 1
    end

    # Nx51s::interactivelyDetermineNewItemOrdinal()
    def self.interactivelyDetermineNewItemOrdinal()
        system('clear')
        items = Nx51s::nx51s()
        return 1 if items.empty?
        items.each{|item|
            puts "- #{Nx51s::toString(item)}"
        }
        LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
    end

    # Nx51s::issueNx51UsingInboxLineInteractive(line)
    def self.issueNx51UsingInboxLineInteractive(line)
        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_f
        description  = line
        catalystType = "Nx51"
        payload1     = nil
        payload2     = nil
        payload3     = Nx51s::decideOrdinal(description)
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx51s::getNx51ByUUIDOrNull(uuid)
    end

    # Nx51s::issueNx51UsingInboxLocationInteractive(location)
    def self.issueNx51UsingInboxLocationInteractive(location)
        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_f
        description  = LucilleCore::askQuestionAnswerAsString("description: ")
        catalystType = "Nx51"
        payload1     = "aion-point"
        payload2     = AionCore::commitLocationReturnHash(AxionElizaBeth.new(), location)
        payload3     = Nx51s::decideOrdinal(description)
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx51s::getNx51ByUUIDOrNull(uuid)
    end

    # --------------------------------------------------
    # Operations

    # Nx51s::toString(nx51)
    def self.toString(nx51)
        uuid = nx51["uuid"]
        contentType = nx51["contentType"]
        str1 = (contentType and contentType.size > 0) ? " (#{nx51["contentType"]})" : ""
        upperStr = Nx51ItemCircuitBreaker::upperStr(nx51)
        "[nx51] (#{"%6.3f" % nx51["ordinal"]}) #{upperStr} #{nx51["description"]}#{str1}"
    end

    # Nx51s::toStringNS16(nx51, rt)
    def self.toStringNS16(nx51, rt)
        uuid = nx51["uuid"]
        contentType = nx51["contentType"]
        str1 = (contentType and contentType.size > 0) ? " (#{nx51["contentType"]})" : ""
        upperStr = Nx51ItemCircuitBreaker::upperStr(nx51)
        "[nx51] (#{"%6.3f" % nx51["ordinal"]}) (#{"%5.2f" % rt}) #{upperStr} #{nx51["description"]}#{str1}"
    end

    # Nx51s::complete(nx51)
    def self.complete(nx51)
        Axion::postAccessCleanUp(nx51["contentType"], nx51["contentPayload"])
        CatalystDatabase::delete(nx51["uuid"])
    end

    # Nx51s::getNextOrdinal()
    def self.getNextOrdinal()
        (([1]+Nx51s::nx51s().map{|nx51| nx51["ordinal"] }).max + 1).floor
    end

    # Nx51s::decideOrdinal(description)
    def self.decideOrdinal(description)
        system("clear")
        puts ""
        puts description.green
        puts ""
        Nx51s::nx51s()
            .sort{|n1, n2| n1["ordinal"] <=> n2["ordinal"] }
            .each{|nx51|
                puts "(#{"%7.3f" % nx51["ordinal"]}) #{Nx51s::toString(nx51)}"
            }
        puts ""
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (empty for last position): ")
        if ordinal == "" then
            Nx51s::getNextOrdinal()
        else
            ordinal.to_f
        end
    end

    # Nx51s::selectOneNx51OrNull()
    def self.selectOneNx51OrNull()
        nx51s = Nx51s::nx51sPerOrdinal()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("Nx51", nx51s, lambda{|nx51| "(#{"%7.3f" % nx51["ordinal"]}) #{Nx51s::toString(nx51)}" })
    end

    # Nx51s::accessContent(nx51)
    def self.accessContent(nx51)
        update = lambda {|contentType, contentPayload|
            nx51["contentType"] = contentType
            nx51["contentPayload"] = contentPayload
            Nx51s::commitNx51ToDisk(nx51)
        }
        Axion::access(nx51["contentType"], nx51["contentPayload"], update)
    end

    # Nx51s::landing(nx51)
    def self.landing(nx51)
        uuid = nx51["uuid"]

        nxball = NxBalls::makeNxBall([uuid, Work::bankaccount()])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx51 item running for more than an hour")
                end
            }
        }

        system("clear")

        loop {

            nx51 = Nx51s::getNx51ByUUIDOrNull(uuid)

            return if nx51.nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: #{Nx51s::toStringNS16(nx51, rt)} (#{BankExtended::runningTimeString(nxball)})".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green

            puts ""

            puts "uuid: #{uuid}".yellow
            puts "coordinates: #{nx51["contentType"]}, #{nx51["contentPayload"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx51["uuid"])}".yellow

            puts ""

            puts "[item   ] access | note | [] | <datecode> | detach running | pause | pursue | exit | completed | update description | update contents | update ordinal | update bound | destroy".yellow

            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("note", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx51["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                next
            end

            if Interpreting::match("access", command) then
                Nx51s::accessContent(nx51)
                next
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid, Work::bankaccount()])
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid, Work::bankaccount()])
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx51s::toString(nx51), Time.new.to_i, [uuid, Work::bankaccount()])
                break
            end

            if Interpreting::match("completed", command) then
                Nx51s::complete(nx51)
                break
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx51["description"])
                if description.size > 0 then
                    CatalystDatabase::updateDescription(nx51["uuid"], description)
                end
                next
            end

            if Interpreting::match("update contents", command) then
                update = nil
                Axion::edit(nx51["contentType"], nx51["contentPayload"], update)
                next
            end

            if Interpreting::match("update ordinal", command) then
                ordinal = Nx51s::decideOrdinal(Nx51s::toString(nx51))
                nx51["ordinal"] = ordinal
                Nx51s::commitNx51ToDisk(nx51)
                break
            end

            if Interpreting::match("update bound", command) then
                Nx51ItemCircuitBreaker::interactivelySetValue(nx51)
                break
            end

            if Interpreting::match("destroy", command) then
                Nx51s::complete(nx51)
                break
            end

            Interpreters::mainMenuInterpreter(command)
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)

        Axion::postAccessCleanUp(nx51["contentType"], nx51["contentPayload"])
    end

    # --------------------------------------------------
    # nx16s

    # Nx51s::selected(nx51)
    def self.selected(nx51)
        puts Nx51s::toString(nx51)
        uuid = nx51["uuid"]
        puts "Starting at #{Time.new.to_s}"
        nxball = NxBalls::makeNxBall([uuid, Work::bankaccount()])
        Nx51s::accessContent(nx51)

        note = StructuredTodoTexts::getNoteOrNull(uuid)
        if note then
            puts "Note ---------------------"
            puts note.green
            puts "--------------------------"
        end

        LucilleCore::pressEnterToContinue()
        Axion::postAccessCleanUp(nx51["contentType"], nx51["contentPayload"])

        loop {
            options = ["exit (default)", "[]", "landing", "destroy"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            NxBalls::closeNxBall(nxball, true)
            if option.nil? then
                break
            end
            if option == "exit (default)" then
                break
            end
            if option == "[]" then
                StructuredTodoTexts::applyT(uuid)
                note = StructuredTodoTexts::getNoteOrNull(uuid)
                if note then
                    puts "Note ---------------------"
                    puts note.green
                    puts "--------------------------" 
                end
            end
            if option == "landing" then
                Nx51s::landing(nx51)

                # Could hve been destroyed
                break if Nx51s::getNx51ByUUIDOrNull(nx51["uuid"]).nil?
            end
            if option == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("detroy '#{Nx51s::toString(nx51)}' ? ", true) then
                    Nx51s::complete(nx51)
                    break
                end
            end
        }
    end

    # Nx51s::ns16OrNull(nx51)
    def self.ns16OrNull(nx51)
        uuid = nx51["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx51s::toStringNS16(nx51, rt)}#{noteStr}"
            .gsub("( 0.00)", "       ")
            .gsub("( 1.00)", "       ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "commands"    => ["..", "landing", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Nx51s::selected(nx51)
                end
                if command == "landing" then
                    Nx51s::landing(nx51)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx51s::toString(nx51)}' ? ", true) then
                        Nx51s::complete(nx51)
                    end
                end
            },
            "selected" => lambda {
                Nx51s::selected(nx51)
            },
            "rt" => rt
        }
    end

    # Nx51s::ns16s()
    def self.ns16s()
        return [] if !Work::isPriorityWork()
        Nx51s::nx51sPerOrdinal()
            .map{|nx51| Nx51s::ns16OrNull(nx51) }
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # --------------------------------------------------

    # Nx51s::nx19s()
    def self.nx19s()
        Nx51s::nx51s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx51s::toString(item),
                "lambda"   => lambda { Nx51s::landing(item) }
            }
        }
    end
end
