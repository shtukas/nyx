# encoding: UTF-8

class Nx50s

    # Nx50s::coreData2SetUUID()
    def self.coreData2SetUUID()
        "catalyst:70853e76-3665-4b2a-8f1e-2f899a93ac06"
    end

    # Nx50s::nx50s()
    def self.nx50s()
        CoreData2::getSet(Nx50s::coreData2SetUUID())
            .sort{|i1, i2| i1["unixtime"]<=>i2["unixtime"] }
    end

    # Nx50s::nx50sForDomain(domain)
    def self.nx50sForDomain(domain)
        Nx50s::nx50s().select{|atom| atom["domain"] == domain }
    end

    # --------------------------------------------------
    # Unixtimes

    # Nx50s::interactivelyDetermineNewItemUnixtimeManuallyPosition(domain)
    def self.interactivelyDetermineNewItemUnixtimeManuallyPosition(domain)
        system("clear")
        items = Nx50s::nx50sForDomain(domain).first(Utils::screenHeight()-3)
        return Time.new.to_f if items.size == 0
        items.each_with_index{|item, i|
            puts "[#{i.to_s.rjust(2)}] #{Nx50s::toString(item)}"
        }
        puts "new first | <n> # index of previous item".yellow
        command = LucilleCore::askQuestionAnswerAsString("> ")
        if command == "new first" then
            return items[0]["unixtime"]-1 
        else
            # Here we interpret as index of an element
            i = command.to_i
            items = items.drop(i)
            if items.size == 0 then
                return Time.new.to_f
            end
            if items.size == 1 then
                return items[0]["unixtime"]+1 
            end
            if items.size >= 2 then
                return (items[0]["unixtime"]+items[1]["unixtime"]).to_f/2
            end
            raise "fa7e03a4-ce26-40c4-82d5-151f98908dca"
        end
        system('clear')
    end

    # Nx50s::getNewMinUnixtime(domain)
    def self.getNewMinUnixtime(domain)
        items = Nx50s::nx50sForDomain(domain)
        if items.empty? then
            return Time.new.to_f
        end
        items.map{|item| item["unixtime"] }.min - 1
    end

    # Nx50s::randomUnixtimeWithinTop10(domain)
    def self.randomUnixtimeWithinTop10(domain)
        items = Nx50s::nx50sForDomain(domain).first(10)
        if items.empty? then
            return Time.new.to_f
        end
        lowerbound = items.map{|item| item["unixtime"] }.min
        upperbound = items.map{|item| item["unixtime"] }.max
        lowerbound + rand * (upperbound-lowerbound)
    end

    # Nx50s::randomUnixtimeWithinRange(domain, n1, n2)
    def self.randomUnixtimeWithinRange(domain, n1, n2)
        items = Nx50s::nx50sForDomain(domain).drop(n1).first(n2-n1)
        if items.empty? then
            return Time.new.to_f
        end
        lowerbound = items.map{|item| item["unixtime"] }.min
        upperbound = items.map{|item| item["unixtime"] }.max
        lowerbound + rand * (upperbound-lowerbound)
    end

    # Nx50s::interactivelyDetermineNewItemUnixtime(domain)
    def self.interactivelyDetermineNewItemUnixtime(domain)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["new first", "top 10", "manually position", "last (default)"])
        if type == "new first" then
            return Nx50s::getNewMinUnixtime(domain)
        end
        if type == "top 10" then
            return Nx50s::randomUnixtimeWithinTop10(domain)
        end
        if type == "manually position" then
            return Nx50s::interactivelyDetermineNewItemUnixtimeManuallyPosition(domain)
        end
        if type == "last (default)" then
            return Time.new.to_i
        end
        if type.nil? then
            return Time.new.to_i
        end
        raise "13a8d479-3d49-415e-8d75-7d0c5d5c695e"
    end

    # --------------------------------------------------
    # Makers

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        atom = CoreData2::interactivelyCreateANewAtomOrNull([Nx50s::coreData2SetUUID()])
        return nil if atom.nil?
        Bank::put("8504debe-2445-4361-a892-daecdc58650d", 1)
        domain = Domain::interactivelySelectDomain()
        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
        atom["unixtime"] = unixtime
        atom["domain"] = domain
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueItemUsingTextOrNull(text, unixtime, domain)
    def self.issueItemUsingText(text, unixtime, domain)
        text = text.strip
        return nil if text == ""
        Bank::put("8504debe-2445-4361-a892-daecdc58650d", 1)
        description = text.lines.first.strip
        atom = CoreData2::issueTextAtomUsingText(SecureRandom.uuid, description, text, [Nx50s::coreData2SetUUID()])
        atom["unixtime"] = unixtime
        atom["domain"] = domain
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueItemUsingLine(line)
    def self.issueItemUsingLine(line)
        Bank::put("8504debe-2445-4361-a892-daecdc58650d", 1)
        atom = CoreData2::issueDescriptionOnlyAtom(SecureRandom.uuid, description, [Nx50s::coreData2SetUUID()])
        domain = Domain::interactivelySelectDomain()
        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
        atom["unixtime"] = unixtime
        atom["domain"] = domain
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueItemUsingLocation(location, unixtime, domain)
    def self.issueItemUsingLocation(location, unixtime, domain)
        Bank::put("8504debe-2445-4361-a892-daecdc58650d", 1)
        description = File.basename(location)
        atom = CoreData2::issueAionPointAtomUsingLocation(SecureRandom.uuid, description, location, [Nx50s::coreData2SetUUID()])
        atom["unixtime"] = unixtime
        atom["domain"] = domain
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueItemUsingURL(url domain)
    def self.issueItemUsingURL(url, domain)
        Bank::put("8504debe-2445-4361-a892-daecdc58650d", 1)
        CoreData2::issueUrlAtomUsingUrl(SecureRandom.uuid, url, url, [Nx50s::coreData2SetUUID()])
        atom["domain"] = domain
        CoreData2::commitAtom2(atom)
    end

    # --------------------------------------------------
    # Operations

    # Nx50s::toString(atom)
    def self.toString(atom)
        "[nx50] #{CoreData2::toString(atom)}"
    end

    # Nx50s::toStringForNS19(atom)
    def self.toStringForNS19(atom)
        "[nx50] #{atom["description"]}"
    end

    # Nx50s::toStringForNS16(atom, rt)
    def self.toStringForNS16(atom, rt)
        "[nx50] (#{"%4.2f" % rt}) #{Nx50s::toString(atom)}"
    end

    # Nx50s::complete(atom)
    def self.complete(atom)
        CoreData2::removeAtomFromSet(atom["uuid"], Nx50s::coreData2SetUUID())
        Bank::put("8504debe-2445-4361-a892-daecdc58650d", -1)
    end

    # --------------------------------------------------
    # nx16s

    # Nx50s::processInboxLastAtDomain(foldername, domain)
    def self.processInboxLastAtDomain(foldername, domain)
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/#{foldername}").each{|location|
            puts "[Nx50] #{domain} (last) #{location}"
            Nx50s::issueItemUsingLocation(location, Time.new.to_f, domain)
            LucilleCore::removeFileSystemLocation(location)
        }
    end

    # Nx50s::run(nx50)
    def self.run(nx50)

        system("clear")

        uuid = nx50["uuid"]
        puts "#{Nx50s::toString(nx50)}".green
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid, Domain::getDomainBankAccount(nx50["domain"])])

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

        loop {

            system("clear")

            puts "#{Nx50s::toString(nx50)} (#{NxBalls::runningTimeString(nxball)})".green
            puts "uuid: #{uuid}".yellow
            puts "coreDataId: #{nx50["coreDataId"]}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow

            puts ""
            puts CoreData2::atomPayloadToText(nx50)
            puts ""

            note = StructuredTodoTexts::getNoteOrNull(uuid)
            if note then
                puts "-- Note ------------------"
                puts note.strip
                puts ""
            end

            puts "access | note | <datecode> | detach running | pause | pursue | update description | update contents | update unixtime | domain | show json | destroy (gg) | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                CoreData2::accessWithOptionToEdit(nx50)
                next
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx50["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx50s::toString(nx50), Time.new.to_i, [uuid])
                break
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid])
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid])
                next
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx50["description"]).strip
                next if description == ""
                nx50["description"] = description
                CoreData2::commitAtom2(nx50)
                next
            end

            if Interpreting::match("update contents", command) then
                atom = CoreData2::interactivelyUpdateAtomTypePayloadPairOrNothing(nx50)
                next
            end

            if Interpreting::match("update unixtime", command) then
                domain = nx50["domain"]
                nx50["unixtime"] = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
                Nx50s::commitItemToDatabase(nx50)
                next
            end

            if Interpreting::match("domain", command) then
                nx50["domain"] = Domain::interactivelySelectDomain()
                Nx50s::commitItemToDatabase(nx50)
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx50)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx50s::toString(nx50)}' ? ", true) then
                    Nx50s::complete(nx50)
                    break
                end
                next
            end

            if command == "gg" then
                Nx50s::complete(nx50)
                break
            end

        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Nx50s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        uuid = nx50["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        return nil if !InternetStatus::ns16ShouldShow(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx50s::toStringForNS16(nx50, rt)}#{noteStr} (rt: #{rt.round(2)})".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Nx50s::run(nx50)
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

    # Nx50s::overflowThreshold(domain)
    def self.overflowThreshold(domain)
        (domain == "(work)") ? 2 : 1
    end

    # Nx50s::structure(domain)
    def self.structure(domain)
        threshold = Nx50s::overflowThreshold(domain)

        q1, q2 = Nx50s::nx50sForDomain(domain)
                    .map{|item| Nx50s::ns16OrNull(item) }
                    .compact
                    .partition{|ns16| ns16["rt"] >= threshold }

        {
            "overflow" => q1,
            "tail"     => q2,
        }
    end

    # Nx50s::ns16s(domain)
    def self.ns16s(domain)

        Quarks::importspread()
        Nx50s::processInboxLastAtDomain("(eva)-last", "(eva)")
        Nx50s::processInboxLastAtDomain("(work)-last", "(work)")

        Nx50s::structure(domain)["tail"]
    end

    # --------------------------------------------------

    # Nx50s::nx19s()
    def self.nx19s()
        Nx50s::nx50s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx50s::toStringForNS19(item),
                "lambda"   => lambda { Nx50s::run(item) }
            }
        }
    end
end
