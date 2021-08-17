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

    # Nx50s::nextNaturalInBetweenUnixtime()
    def self.nextNaturalInBetweenUnixtime()
        unixtimes = Nx50s::nx50s()
                        .drop(10)
                        .map{|nx50| nx50["unixtime"] }
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

    # Nx50s::interactivelyDetermineNewItemUnixtimeOrNull()
    def self.interactivelyDetermineNewItemUnixtimeOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["select", "natural (default)"])
        return Nx50s::nextNaturalInBetweenUnixtime() if type.nil?
        if type == "select" then
            system('clear')
            puts "Select the before item:"
            items = Nx50s::nx50s().first(50)
            return Time.new.to_i if items.empty?
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Nx50s::toString(item) })
            return nil if item.nil?
            loop {
                return nil if items.size < 2
                if items[0]["uuid"] == item["uuid"] then
                    return (items[0]["unixtime"]+items[1]["unixtime"]).to_f/2
                end
                items.shift
                next
            }
        end
        if type == "natural" then
            return Nx50s::nextNaturalInBetweenUnixtime()
        end
    end

    # Nx50s::viennaIssueNx50UsingURL(url)
    def self.viennaIssueNx50UsingURL(url)
        uuid         = SecureRandom.uuid
        unixtime     = Nx50s::nextNaturalInBetweenUnixtime()
        description  = url
        catalystType = "Nx50"
        payload1     = "url"
        payload2     = url
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::inboxFilePickupIssueNx50UsingLocation(location)
    def self.inboxFilePickupIssueNx50UsingLocation(location)
        uuid         = SecureRandom.uuid
        unixtime     = Nx50s::nextNaturalInBetweenUnixtime()
        description  = File.basename(location) 
        catalystType = "Nx50"
        payload1     = "aion-point"
        payload2     = AionCore::commitLocationReturnHash(AxionElizaBeth.new(), location)
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingInboxLineInteractive(line)
    def self.issueNx50UsingInboxLineInteractive(line)
        uuid         = SecureRandom.uuid
        unixtime     = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)
        description  = line
        catalystType = "Nx50"
        payload1     = nil
        payload2     = nil
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingInboxLocationInteractive(location)
    def self.issueNx50UsingInboxLocationInteractive(location)
        uuid         = SecureRandom.uuid
        unixtime     = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)
        description  = LucilleCore::askQuestionAnswerAsString("description: ")
        catalystType = "Nx50"
        payload1     = "aion-point"
        payload2     = AionCore::commitLocationReturnHash(AxionElizaBeth.new(), location)
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        coordinates  = Axion::interactivelyIssueNewCoordinatesOrNull()

        unixtime     = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)

        catalystType = "Nx50"
        payload1     = coordinates ? coordinates["contentType"] : nil
        payload2     = coordinates ? coordinates["contentPayload"] : nil
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

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
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s-Completion-Log.txt", "a"){|f| f.puts("#{Time.new.to_s}|#{Time.new.to_i}|#{Nx50s::toString(nx50)}") }
        Axion::postAccessCleanUp(nx50["contentType"], nx50["contentPayload"])
        CatalystDatabase::delete(nx50["uuid"])
    end

    # Nx50s::access(nx50)
    def self.access(nx50)

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
                update = lambda {|contentType, contentPayload|
                    nx50["contentType"] = contentType
                    nx50["contentPayload"] = contentPayload
                    Nx50s::commitNx50ToDisk(nx50)
                }
                Axion::access(nx50["contentType"], nx50["contentPayload"], update)
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
                update = nil
                Axion::edit(nx50["contentType"], nx50["contentPayload"], update)
                next
            end

            if Interpreting::match("update unixtime", command) then
                nx50["unixtime"] = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)
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

    # Nx50s::getCompletionLogUnixtimes()
    def self.getCompletionLogUnixtimes()
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s-Completion-Log.txt"
        IO.read(filepath)
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0}
            .map{|line| line.split("|")[1].to_i }
    end

    # Nx50s::completionLogSize(days)
    def self.completionLogSize(days)
        horizon = Time.new.to_i - days*86400
        Nx50s::getCompletionLogUnixtimes().select{|unixtime| unixtime >= horizon }.size
    end

    # --------------------------------------------------
    # nx16s

    # Nx50s::hoursOverThePast21Days(nx50)
    def self.hoursOverThePast21Days(nx50)
        Bank::valueOverTimespan(nx50["uuid"], 86400*21).to_f/3600
    end

    # Nx50s::hoursDoneSinceLastSaturday(nx50)
    def self.hoursDoneSinceLastSaturday(nx50)
        Utils::datesSinceLastSaturday().map{|date| Bank::valueAtDate(nx50["uuid"], date)}.inject(0, :+).to_f/3600
    end

    # Nx50s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        uuid = nx50["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        hs1 = Nx50s::hoursDoneSinceLastSaturday(nx50)
        hs2 = Nx50s::hoursOverThePast21Days(nx50)
        return nil if (hs1 > 5 or hs2 > 10)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        return nil if rt > 1
        announce = "(#{"%4.2f" % rt}) #{Nx50s::toString(nx50)}".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "access"   => lambda{ Nx50s::access(nx50) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx50s::toString(nx50)}' ? ", true) then
                    Nx50s::complete(nx50)
                end
            },
            "[]"      => lambda { StructuredTodoTexts::applyT(uuid) },
            "rt"      => rt,
            "sinceLastSaturday" => " #{(100*hs1.to_f/5).round(2)} % of 5 hours",
            "overThePast21Days" => " #{(100*hs2.to_f/10).round(2)} % of 10 hours",
            "metric"  => nil,
            "commands" => ["access", "done"],
            "interpreter" => nil
        }
    end

    # Nx50s::ns16s()
    def self.ns16s()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Nx50s").each{|location|
            Nx50s::inboxFilePickupIssueNx50UsingLocation(location)
            LucilleCore::removeFileSystemLocation(location)
        }

        base = 0.2 + 0.8*BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7").to_f/3

        ns16s = Nx50s::nx50s()
            .reduce([]){|ns16s, nx50|
                if ns16s.size < 3 then
                    ns16 = Nx50s::ns16OrNull(nx50)
                    if ns16 then
                        ns16s << ns16
                    end
                end
                ns16s
            }
            .sort{|n1, n2| n1["rt"] <=> n2["rt"] }
            .reverse

        Metrics::lift1(ns16s, base)
    end

    # --------------------------------------------------

    # Nx50s::nx19s()
    def self.nx19s()
        Nx50s::nx50s().map{|item|
            {
                "announce" => Nx50s::toString(item),
                "lambda"   => lambda { Nx50s::access(item) }
            }
        }
    end
end
