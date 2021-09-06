# encoding: UTF-8

class Nx50s

    # Nx50s::databaseItemToNx50(item)
    def self.databaseItemToNx50(item)
        item["contentType"]    = item["payload1"]
        item["contentPayload"] = item["payload2"]
        item
    end

    # Nx50s::nx50s()
    def self.nx50s()
        CatalystDatabase::getItemsByCatalystType("Nx50").map{|item|
            Nx50s::databaseItemToNx50(item)
        }
    end

    # Nx50s::commitNx50ToDisk(nx50)
    def self.commitNx50ToDisk(nx50)
        uuid         = nx50["uuid"]
        unixtime     = nx50["unixtime"]
        description  = nx50["description"]
        catalystType = "Nx50"
        payload1     = nx50["contentType"]
        payload2     = nx50["contentPayload"]
        payload3     = nil
        payload4     = nil 
        payload5     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, payload4, payload5)
    end

    # Nx50s::getNx50ByUUIDOrNull(uuid)
    def self.getNx50ByUUIDOrNull(uuid)
        item = CatalystDatabase::getItemByUUIDOrNull(uuid)
        return nil if item.nil?
        Nx50s::databaseItemToNx50(item)
    end

    # --------------------------------------------------
    # Next Gen

    # Nx50s::getNextGenUUIDS()
    def self.getNextGenUUIDS()
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "3a249511-086b-4160-b33d-28550eb77113", "[]"))
    end

    # Nx50s::addToNextGenUUIDs(uuid)
    def self.addToNextGenUUIDs(uuid)
        uuids = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "3a249511-086b-4160-b33d-28550eb77113", "[]")) + [uuid]
        uuids = uuids & Nx50s::nx50s().map{|i| i["uuid"] }
        KeyValueStore::set(nil, "3a249511-086b-4160-b33d-28550eb77113", JSON.generate(uuids))
    end

    # Nx50s::getNextGenUnixtime()
    def self.getNextGenUnixtime()
        nexGenUUIDs = Nx50s::getNextGenUUIDS()
        nx50s = Nx50s::nx50s()
        while nx50s.any?{|nx50| nexGenUUIDs.include?(nx50["uuid"]) } do
            nx50s = nx50s.drop(1)
        end
        if nx50s.size < 2 then
            return Time.new.to_f
        end
        (nx50s[0]["unixtime"] + nx50s[1]["unixtime"]).to_f/2
    end

    # Nx50s::interactivelyDetermineNewItemUnixtime()
    def self.interactivelyDetermineNewItemUnixtime()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["select", "natural (default)"])
        if type.nil? then
            return Nx50s::getNextGenUnixtime()
        end
        if type == "natural (default)" then
            return Nx50s::getNextGenUnixtime()
        end
        if type == "select" then
            items = Nx50s::nx50s().first(50)
            return Nx50s::getNextGenUnixtime() if items.size < 2
            system('clear')
            puts "Select the before item:"
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Nx50s::toString(item) })
            if item.nil? then
                return Time.new.to_f
            end
            while items.any?{|i| i["uuid"] == item["uuid"] } do
                items = items.drop(1)
            end
            if items.size < 2 then
                return Time.new.to_f
            end
            return (items[0]["unixtime"]+items[1]["unixtime"]).to_f/2
        end
        raise "13a8d479-3d49-415e-8d75-7d0c5d5c695e"
    end

    # Nx50s::determineItemPositionOrNull(nx50)
    def self.determineItemPositionOrNull(nx50)
        Nx50s::nx50s().map{|i| i["uuid"] }.index(nx50["uuid"])
    end

    # --------------------------------------------------
    # Makers

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        coordinates  = Axion::interactivelyIssueNewCoordinatesOrNull()

        unixtime     = Nx50s::interactivelyDetermineNewItemUnixtime()

        catalystType = "Nx50"
        payload1     = coordinates ? coordinates["contentType"] : nil
        payload2     = coordinates ? coordinates["contentPayload"] : nil
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        Nx50s::addToNextGenUUIDs(uuid)

        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingLineInteractively(line)
    def self.issueNx50UsingLineInteractively(line)
        uuid         = SecureRandom.uuid
        unixtime     = Nx50s::interactivelyDetermineNewItemUnixtime()
        description  = line
        catalystType = "Nx50"
        payload1     = nil
        payload2     = nil
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx50s::addToNextGenUUIDs(uuid)
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingDescriptionAndTextInteractively(description, text)
    def self.issueNx50UsingDescriptionAndTextInteractively(description, text)
        uuid         = SecureRandom.uuid
        unixtime     = Nx50s::interactivelyDetermineNewItemUnixtime()
        catalystType = "Nx50"
        payload1     = "text"
        payload2     = AxionBinaryBlobsService::putBlob(text)
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx50s::addToNextGenUUIDs(uuid)
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingURL(url)
    def self.issueNx50UsingURL(url)
        uuid         = SecureRandom.uuid
        unixtime     = Nx50s::getNextGenUnixtime()
        description  = url
        catalystType = "Nx50"
        payload1     = "url"
        payload2     = url
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx50s::addToNextGenUUIDs(uuid)
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingLocation(location)
    def self.issueNx50UsingLocation(location)
        uuid         = SecureRandom.uuid
        unixtime     = Nx50s::getNextGenUnixtime()
        description  = File.basename(location) 
        catalystType = "Nx50"
        payload1     = "aion-point"
        payload2     = AionCore::commitLocationReturnHash(AxionElizaBeth.new(), location)
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx50s::addToNextGenUUIDs(uuid)
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # --------------------------------------------------
    # Operations

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        contentType = nx50["contentType"]
        str1 = (contentType and contentType.size > 0) ? " (#{contentType})" : ""
        "[nx50] #{nx50["description"]}#{str1}"
    end

    # Nx50s::complete(nx50)
    def self.complete(nx50)
        Axion::postAccessCleanUp(nx50["contentType"], nx50["contentPayload"])
        CatalystDatabase::delete(nx50["uuid"])
    end

    # Nx50s::accessContent(nx50)
    def self.accessContent(nx50)
        update = lambda {|contentType, contentPayload|
            nx50["contentType"] = contentType
            nx50["contentPayload"] = contentPayload
            Nx50s::commitNx50ToDisk(nx50)
        }
        Axion::access(nx50["contentType"], nx50["contentPayload"], update)
    end

    # Nx50s::landing(nx50)
    def self.landing(nx50)

        uuid = nx50["uuid"]

        nxball = NxBalls::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx50 item running for more than an hour")
                end
            }
        }

        system("clear")

        loop {

            nx50 = Nx50s::getNx50ByUUIDOrNull(uuid)

            return if nx50.nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: (#{"%.3f" % rt}) #{Nx50s::toString(nx50)} (#{BankExtended::runningTimeString(nxball)})".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green

            puts ""

            puts "uuid: #{uuid}".yellow
            puts "coordinates: #{nx50["contentType"]}, #{nx50["contentPayload"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow

            puts ""

            puts "[item   ] access | note | [] | <datecode> | detach running | pause | exit | pursue | completed | update description | update contents | update unixtime | destroy".yellow

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
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx50["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])
                next
            end

            if Interpreting::match("access", command) then
                Nx50s::accessContent(nx50)
                next
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx50s::toString(nx50), Time.new.to_i, [uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])
                break
            end

            if Interpreting::match("completed", command) then
                Nx50s::complete(nx50)
                break
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx50["description"])
                if description.size > 0 then
                    CatalystDatabase::updateDescription(nx50["uuid"], description)
                end
                next
            end

            if Interpreting::match("update contents", command) then
                update = lambda {|contentType, contentPayload|
                    nx50["contentType"] =  contentType
                    nx50["contentPayload"] = contentPayload
                    Nx50s::commitNx50ToDisk(nx50)
                }
                Axion::edit(nx50["contentType"], nx50["contentPayload"], update)
                next
            end

            if Interpreting::match("update unixtime", command) then
                nx50["unixtime"] = Nx50s::interactivelyDetermineNewItemUnixtime()
                Nx50s::commitNx50ToDisk(nx50)
                next
            end

            if Interpreting::match("destroy", command) then
                Nx50s::complete(nx50)
                break
            end

            Interpreters::mainMenuInterpreter(command)
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)

        Axion::postAccessCleanUp(nx50["contentType"], nx50["contentPayload"])
    end

    # --------------------------------------------------
    # nx16s

    # Nx50s::run(nx50)
    def self.run(nx50)

        puts Nx50s::toString(nx50)

        uuid = nx50["uuid"]
        puts "Starting at #{Time.new.to_s}"
        nxball = NxBalls::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])

        Nx50s::accessContent(nx50)

        note = StructuredTodoTexts::getNoteOrNull(uuid)
        if note then
            puts "Note ---------------------"
            puts note.green
            puts "--------------------------"
        end

        LucilleCore::pressEnterToContinue()

        loop {

            puts "exit (default) | [] | landing | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            break if command == "exit"

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                note = StructuredTodoTexts::getNoteOrNull(uuid)
                if note then
                    puts "Note ---------------------"
                    puts note.green
                    puts "--------------------------"
                end
                next
            end

            if command == "landing" then
                Nx50s::landing(nx50)
                break if Nx50s::getNx50ByUUIDOrNull(nx50["uuid"]).nil? # Could have been destroyed
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("detroy '#{Nx50s::toString(nx50)}' ? ", true) then
                    Nx50s::complete(nx50)
                    break
                end
                next
            end
        }

        Axion::postAccessCleanUp(nx50["contentType"], nx50["contentPayload"])

        NxBalls::closeNxBall(nxball, true)
    end

    # Nx50s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        uuid = nx50["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        return nil if rt > 1
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx50s::toString(nx50)}#{noteStr} (rt: #{rt.round(2)})".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "commands"    => ["..", "landing", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Nx50s::run(nx50)
                end
                if command == "landing" then
                    Nx50s::landing(nx50)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx50s::toString(nx50)}' ? ", true) then
                        Nx50s::complete(nx50)
                    end
                end
            },
            "run" => lambda {
                Nx50s::run(nx50)
            },
            "rt" => rt
        }
    end

    # Nx50s::ns16s()
    def self.ns16s()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Inbox").each{|location|
            Nx50s::issueNx50UsingLocation(location)
            LucilleCore::removeFileSystemLocation(location)
        }

        Nx50s::nx50s()
            .reduce([]){|ns16s, nx50|
                if ns16s.size < 5 then
                    ns16 = Nx50s::ns16OrNull(nx50)
                    if ns16 then
                        ns16s << ns16
                    end
                end
                ns16s
            }
            .sort{|n1, n2| n1["rt"] <=> n2["rt"] }
    end

    # --------------------------------------------------

    # Nx50s::nx19s()
    def self.nx19s()
        Nx50s::nx50s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx50s::toString(item),
                "lambda"   => lambda { Nx50s::landing(item) }
            }
        }
    end
end
