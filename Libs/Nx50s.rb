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
        Nx50s::nx50s()
            .select{|atom| atom["domain"] == domain }
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
        "[nx50] #{CoreData2::toString(atom)} (#{atom["type"]})"
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

    # Nx50s::importspread()
    def self.importspread()
        locations = LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s Spread")
 
        if locations.size > 0 then
 
            unixtimes = Nx50s::items().map{|item| item["unixtime"] }
 
            if unixtimes.size < 2 then
                start1 = Time.new.to_f - 86400
                end1   = Time.new.to_f
            else
                start1 = unixtimes.min
                end1   = [unixtimes.max, Time.new.to_f].max
            end
 
            spread = end1 - start1
 
            step = spread.to_f/locations.size
 
            cursor = start1
 
            #puts "Nx50s Spread"
            #puts "  start : #{Time.at(start1).to_s} (#{start1})"
            #puts "  end   : #{Time.at(end1).to_s} (#{end1})"
            #puts "  spread: #{spread}"
            #puts "  step  : #{step}"
 
            locations.each{|location|
                cursor = cursor + step
                puts "[quark] (#{Time.at(cursor).to_s}) #{location}"
                Nx50s::issueItemUsingLocation(location, cursor, "(eva)")
                LucilleCore::removeFileSystemLocation(location)
            }
        end
    end

    # --------------------------------------------------
    # nx16s

    # Nx50s::run(nx50)
    def self.run(nx50)

        system("clear")

        uuid = nx50["uuid"]

        NxBallsService::issueOrIncreaseOwnerCount(uuid, [uuid, Domain::getDomainBankAccount(nx50["domain"])])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - NxBallsService::cursorUnixtimeOrNow(uuid)) >= 600 then
                    NxBallsService::marginCall(uuid, false)
                end

                if (Time.new.to_i - NxBallsService::startUnixtimeOrNow(uuid)) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx50 item running for more than an hour")
                end
            }
        }

        loop {

            system("clear")

            puts "#{Nx50s::toString(nx50)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
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

            puts "access | note | <datecode> | update description | update contents | update unixtime | rotate | domain | show json | destroy (gg) | exit".yellow

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
                CoreData2::commitAtom2(nx50)
                next
            end

            if Interpreting::match("rotate", command) then
                nx50["unixtime"] = Time.new.to_f
                CoreData2::commitAtom2(nx50)
                break
            end

            if Interpreting::match("domain", command) then
                nx50["domain"] = Domain::interactivelySelectDomain()
                CoreData2::commitAtom2(nx50)
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
        NxBallsService::decreaseOwnerCountOrClose(uuid, true)
    end

    # Nx50s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        uuid = nx50["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        return nil if !InternetStatus::ns16ShouldShow(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        tx = Bank::valueAtDate(uuid, Utils::today()).to_f/3600
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx50s::toStringForNS16(nx50, rt)}#{noteStr} (today: #{tx.round(2)}, rt: #{rt.round(2)})".gsub("(0.00)", "      ").gsub("(today: 0.0, rt: 0.0)", "").strip
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
            "start-land" => lambda {
                Nx50s::run(nx50)
            },
            "bank-accounts" => [Domain::getDomainBankAccount(nx50["domain"])],
            "rt" => rt
        }
    end

    # Nx50s::overflowThreshold(domain)
    def self.overflowThreshold(domain)
        (domain == "(work)") ? 2 : 1
    end

    # Nx50s::ns16s(domain)
    def self.ns16s(domain)
        Nx50s::importspread()
        threshold = Nx50s::overflowThreshold(domain)

        ns16s = Nx50s::nx50sForDomain(domain)
                    .map{|item| Nx50s::ns16OrNull(item) }
                    .compact

        overflow, tail = ns16s.partition{|ns16| Bank::valueAtDate(ns16["uuid"], Utils::today()).to_f/3600 > threshold }
        overflow = overflow.map{|ns16|
            ns16["announce"] = ns16["announce"].red
            ns16
        }
        tail.take(1) + overflow + tail.drop(1)
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
