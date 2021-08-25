# encoding: UTF-8

class Nx25s

    # Nx25s::databaseItemToNx25(item)
    def self.databaseItemToNx25(item)
        item["contentType"]    = item["payload1"]
        item["contentPayload"] = item["payload2"]
        item
    end

    # Nx25s::nx25s()
    def self.nx25s()
        CatalystDatabase::getItemsByCatalystType("Nx25").map{|item|
            Nx25s::databaseItemToNx25(item)
        }
    end

    # Nx25s::commitNx25ToDisk(nx25)
    def self.commitNx25ToDisk(nx25)
        uuid         = nx25["uuid"]
        unixtime     = nx25["unixtime"]
        description  = nx25["description"]
        catalystType = "Nx25"
        payload1     = nx25["contentType"]
        payload2     = nx25["contentPayload"]
        payload3     = nil
        payload4     = nil 
        payload5     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, payload4, payload5)
    end

    # Nx25s::getNx25ByUUIDOrNull(uuid)
    def self.getNx25ByUUIDOrNull(uuid)
        item = CatalystDatabase::getItemByUUIDOrNull(uuid)
        return nil if item.nil?
        Nx25s::databaseItemToNx25(item)
    end

    # --------------------------------------------------

    # Nx25s::nextNaturalInBetweenUnixtime()
    def self.nextNaturalInBetweenUnixtime()
        unixtimes = Nx25s::nx25s()
                        .drop(10)
                        .map{|nx25| nx25["unixtime"] }
        packet = unixtimes
            .zip(unixtimes.drop(1))
            .select{|pair| pair[1] }
            .map{|pair|
                {
                    "unixtime"   => pair[0],
                    "difference" => pair[1] - pair[0]
                }
            }
            .select{|packet|
                packet["difference"] >= 1
            }
            .first
        return Time.new.to_i if packet.nil?
        packet["unixtime"] + 0.6 # We started with a difference of 2 + rand between two consecutive items.
    end

    # Nx25s::viennaIssueNx25UsingURL(url)
    def self.viennaIssueNx25UsingURL(url)
        uuid         = SecureRandom.uuid
        unixtime     = Nx25s::nextNaturalInBetweenUnixtime()
        description  = url
        catalystType = "Nx25"
        payload1     = "url"
        payload2     = url
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        Nx25s::getNx25ByUUIDOrNull(uuid)
    end

    # Nx25s::inboxFilePickupIssueNx25UsingLocation(location)
    def self.inboxFilePickupIssueNx25UsingLocation(location)
        uuid         = SecureRandom.uuid
        unixtime     = Nx25s::nextNaturalInBetweenUnixtime()
        description  = File.basename(location) 
        catalystType = "Nx25"
        payload1     = "aion-point"
        payload2     = AionCore::commitLocationReturnHash(AxionElizaBeth.new(), location)
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        Nx25s::getNx25ByUUIDOrNull(uuid)
    end

    # Nx25s::issueNx25UsingInboxLineInteractive(line)
    def self.issueNx25UsingInboxLineInteractive(line)
        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_f
        description  = line
        catalystType = "Nx25"
        payload1     = nil
        payload2     = nil
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx25s::getNx25ByUUIDOrNull(uuid)
    end

    # Nx25s::issueNx25UsingInboxText(description, text)
    def self.issueNx25UsingInboxText(description, text)
        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_f
        catalystType = "Nx25"
        payload1     = "text"
        payload2     = AxionBinaryBlobsService::putBlob(text)
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx25s::getNx25ByUUIDOrNull(uuid)
    end

    # Nx25s::issueNx25UsingInboxLocationInteractive(location)
    def self.issueNx25UsingInboxLocationInteractive(location)
        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_f
        description  = LucilleCore::askQuestionAnswerAsString("description: ")
        catalystType = "Nx25"
        payload1     = "aion-point"
        payload2     = AionCore::commitLocationReturnHash(AxionElizaBeth.new(), location)
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx25s::getNx25ByUUIDOrNull(uuid)
    end

    # --------------------------------------------------
    # Operations

    # Nx25s::toString(nx25)
    def self.toString(nx25)
        contentType = nx25["contentType"]
        str1 = (contentType and contentType.size > 0) ? " (#{contentType})" : ""
        "[nx25] #{nx25["description"]}#{str1}"
    end

    # Nx25s::complete(nx25)
    def self.complete(nx25)
        Axion::postAccessCleanUp(nx25["contentType"], nx25["contentPayload"])
        CatalystDatabase::delete(nx25["uuid"])
    end

    # Nx25s::accessContent(nx25)
    def self.accessContent(nx25)
        update = lambda {|contentType, contentPayload|
            nx25["contentType"] = contentType
            nx25["contentPayload"] = contentPayload
            Nx25s::commitNx25ToDisk(nx25)
        }
        Axion::access(nx25["contentType"], nx25["contentPayload"], update)
    end

    # Nx25s::landing(nx25)
    def self.landing(nx25)

        uuid = nx25["uuid"]

        nxball = NxBalls::makeNxBall([uuid, "Nx25s-DE6269A0-B816-4A86-9C8F-FBE332D044C3"])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx25 item running for more than an hour")
                end
            }
        }

        system("clear")

        loop {

            nx25 = Nx25s::getNx25ByUUIDOrNull(uuid)

            return if nx25.nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: (#{"%.3f" % rt}) #{Nx25s::toString(nx25)} (#{BankExtended::runningTimeString(nxball)})".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green

            puts ""

            puts "uuid: #{uuid}".yellow
            puts "coordinates: #{nx25["contentType"]}, #{nx25["contentPayload"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx25["uuid"])}".yellow

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
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx25["uuid"]) || "")
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
                nxball = NxBalls::makeNxBall([uuid, "Nx25s-DE6269A0-B816-4A86-9C8F-FBE332D044C3"])
                next
            end

            if Interpreting::match("access", command) then
                Nx25s::accessContent(nx25)
                next
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid, "Nx25s-DE6269A0-B816-4A86-9C8F-FBE332D044C3"])
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx25s::toString(nx25), Time.new.to_i, [uuid, "Nx25s-DE6269A0-B816-4A86-9C8F-FBE332D044C3"])
                break
            end

            if Interpreting::match("completed", command) then
                Nx25s::complete(nx25)
                break
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx25["description"])
                if description.size > 0 then
                    CatalystDatabase::updateDescription(nx25["uuid"], description)
                end
                next
            end

            if Interpreting::match("update contents", command) then
                update = nil
                Axion::edit(nx25["contentType"], nx25["contentPayload"], update)
                next
            end

            if Interpreting::match("update unixtime", command) then
                nx25["unixtime"] = Time.new.to_f
                Nx25s::commitNx25ToDisk(nx25)
                next
            end

            if Interpreting::match("destroy", command) then
                Nx25s::complete(nx25)
                break
            end

            Interpreters::mainMenuInterpreter(command)
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)

        Axion::postAccessCleanUp(nx25["contentType"], nx25["contentPayload"])
    end

    # --------------------------------------------------
    # nx16s

    # Nx25s::selected(nx25)
    def self.selected(nx25)
        uuid = nx25["uuid"]
        puts "Starting at #{Time.new.to_s}"
        nxball = NxBalls::makeNxBall([uuid, "Nx25s-DE6269A0-B816-4A86-9C8F-FBE332D044C3"])
        Nx25s::accessContent(nx25)

        note = StructuredTodoTexts::getNoteOrNull(uuid)
        if note then
            puts "Note ---------------------"
            puts note.green
            puts "--------------------------"
        end

        LucilleCore::pressEnterToContinue()

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
                next
            end
            if option == "landing" then
                Nx25s::landing(nx25)

                # Could hve been destroyed
                break if Nx25s::getNx25ByUUIDOrNull(nx25["uuid"]).nil?
            end
            if option == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("detroy '#{Nx25s::toString(nx25)}' ? ", true) then
                    Nx25s::complete(nx25)
                    break
                end
                next
            end
        }
    end

    # Nx25s::ns16OrNull(nx25)
    def self.ns16OrNull(nx25)
        uuid = nx25["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx25s::toString(nx25)}#{noteStr}"
        {
            "uuid"     => uuid,
            "announce" => announce,
            "commands"    => ["..", "landing", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Nx25s::selected(nx25)
                end
                if command == "landing" then
                    Nx25s::landing(nx25)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx25s::toString(nx25)}' ? ", true) then
                        Nx25s::complete(nx25)
                    end
                end
            },
            "selected" => lambda {
                Nx25s::selected(nx25)
            }
        }
    end

    # Nx25s::ns16s()
    def self.ns16s()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Nx25s-Inbox").each{|location|
            Nx25s::inboxFilePickupIssueNx25UsingLocation(location)
            LucilleCore::removeFileSystemLocation(location)
        }

        Nx25s::nx25s()
            .map{|nx25| Nx25s::ns16OrNull(nx25) }
    end

    # --------------------------------------------------

    # Nx25s::nx19s()
    def self.nx19s()
        Nx25s::nx25s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx25s::toString(item),
                "lambda"   => lambda { Nx25s::landing(item) }
            }
        }
    end
end
