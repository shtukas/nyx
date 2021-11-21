# encoding: UTF-8

class Nx50s

    # Nx50s::coreData2SetUUID()
    def self.coreData2SetUUID()
        "catalyst:70853e76-3665-4b2a-8f1e-2f899a93ac06"
    end

    # Nx50s::nx50s()
    def self.nx50s()
        CoreData2::getSet(Nx50s::coreData2SetUUID())
            .map{|atom|
                Domain::ensureDomainCorrection(
                    atom["domain"], 
                    lambda{|atom|
                        puts "Correcting domain for '#{Nx50s::toString(atom)}'"
                        atom["domain"] = Domain::interactivelySelectDomain()
                        puts JSON.pretty_generate(atom)
                        CoreData2::commitAtom2(atom)
                    }, 
                    atom
                )
                atom
            }
            .map{|atom|
                if !atom["isQuark"] and !atom["isVienna"] then
                    atom["isHandMade"] = true
                end
                atom
            }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # Nx50s::nx50sForDomain(domain)
    def self.nx50sForDomain(domain)
        Nx50s::nx50s()
            .select{|atom| atom["domain"] == domain }
    end

    # --------------------------------------------------
    # Unixtimes

    # Nx50s::getNewUnixtime()
    def self.getNewUnixtime()
        Time.new.to_f
    end

    # --------------------------------------------------
    # Makers

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        atom = CoreData2::interactivelyCreateANewAtomOrNull([Nx50s::coreData2SetUUID()])
        return nil if atom.nil?
        domain = Domain::interactivelySelectDomain()
        atom["unixtime"] = Nx50s::getNewUnixtime()
        atom["domain"] = domain
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueItemUsingLine(line)
    def self.issueItemUsingLine(line)
        atom = CoreData2::issueDescriptionOnlyAtom(SecureRandom.uuid, description, [Nx50s::coreData2SetUUID()])
        domain = Domain::interactivelySelectDomain()
        atom["unixtime"] = Nx50s::getNewUnixtime()
        atom["domain"] = domain
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueItemUsingLocation(location, unixtime, domain)
    def self.issueItemUsingLocation(location, unixtime, domain)
        description = File.basename(location)
        atom = CoreData2::issueAionPointAtomUsingLocation(SecureRandom.uuid, description, location, [Nx50s::coreData2SetUUID()])
        atom["unixtime"] = unixtime
        atom["domain"] = domain
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueCommunicationItemUsingLocation(location, domain)
    def self.issueCommunicationItemUsingLocation(location, domain)
        description = File.basename(location)
        atom = CoreData2::issueAionPointAtomUsingLocation(SecureRandom.uuid, description, location, [Nx50s::coreData2SetUUID()])
        atom["unixtime"] = 1 + rand # That's how we ensure that they come after everybody
        atom["domain"] = domain
        atom["isCommunication"] = true
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueViennaURL(url)
    def self.issueViennaURL(url)
        atom = CoreData2::issueUrlAtomUsingUrl(SecureRandom.uuid, url, url, [Nx50s::coreData2SetUUID()])
        atom["unixtime"] = Nx50s::getNewUnixtime()
        atom["domain"]   = "(eva)"
        atom["isVienna"] =  true
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

    # Nx50s::tx23s()
    def self.tx23s()
       [
            {
                "attribute" => "isQuark",
                "account"   => "9979D5C8-091D-4929-9E2E-2191FA1291B6"
            },
            {
                "attribute" => "isVienna",
                "account"   => "35EFF9F7-1A58-48C4-B0CD-3499A0683A4D"
            },
            {
                "attribute" => "isHandMade",
                "account"   => "88245B96-DE84-4A4F-9F7B-50F7C907204C"
            }
        ]
    end

    # Nx50s::run(nx50)
    def self.run(nx50)

        itemToBankAccounts = lambda{|item|
            accounts = []
            accounts << item["uuid"]
            accounts << Domain::getDomainBankAccount(item["domain"])
            Nx50s::tx23s().each{|tx23|
                if item[tx23["attribute"]] then
                    accounts << tx23["account"]
                end
            }
            accounts
        }

        system("clear")

        uuid = nx50["uuid"]

        NxBallsService::issue(uuid, Nx50s::toString(nx50), itemToBankAccounts.call(nx50))

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - NxBallsService::cursorUnixtimeOrNow(uuid)) >= 600 then
                    NxBallsService::marginCall(uuid)
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

            puts CoreData2::atomPayloadToText(nx50)

            note = StructuredTodoTexts::getNoteOrNull(nx50["uuid"])
            if note then
                puts "note:\n#{note}".green
            end

            puts "access | note | <datecode> | update description | update contents | rotate | domain | show json | destroy (gg) | exit".yellow

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
        NxBallsService::closeWithAsking(uuid)
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
            "NS198"    => "ns16:Nx501",
            "announce" => announce,
            "commands" => ["..", "done"],
            "Nx50"     => nx50,
            "rt"       => rt
        }
    end

    # Nx50s::overflowThreshold(domain)
    def self.overflowThreshold(domain)
        (domain == "(work)") ? 2 : 1
    end

    # Nx50s::tx24s()
    def self.tx24s()
        Nx50s::tx23s()
            .map{|tx23|
                {
                    "tx23" => tx23,
                    "rt"   => BankExtended::stdRecoveredDailyTimeInHours(tx23["account"])
                }
            }
            .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
    end

    # Nx50s::itemsCollapseToTx24s(items)
    def self.itemsCollapseToTx24s(items)
        Nx50s::tx24s()
            .map{|tx24|
                items.select{|item| item[tx24["tx23"]["attribute"]] }
            }
            .flatten
    end

    # Nx50s::ns16sCommunications(domain)
    def self.ns16sCommunications(domain)
        Nx50s::nx50sForDomain(domain)
            .select{|item| item["isCommunication"] }
            .map{|item| Nx50s::ns16OrNull(item) }
            .compact
    end

    # Nx50s::ns16s(domain)
    def self.ns16s(domain)
        Nx50s::importspread()
        threshold = Nx50s::overflowThreshold(domain)

        items = Nx50s::nx50sForDomain(domain)
                    .select{|item| !item["isCommunication"] }

        if domain == "(eva)" then
            items =  Nx50s::itemsCollapseToTx24s(items).first(50)
        end

        ns16s = items
                    .map{|item| Nx50s::ns16OrNull(item) }
                    .compact

        overflow, tail = ns16s.partition{|ns16| Bank::valueAtDate(ns16["uuid"], Utils::today()).to_f/3600 > threshold }
        tail
    end

    # --------------------------------------------------

    # Nx50s::dx()
    def self.dx()
        x1 = Nx50s::tx24s()
                .map{|tx24| "#{tx24["tx23"]["attribute"]}, #{tx24["rt"].round(2)}" }
                .join(", ")
        "(Nx50: #{x1})"
    end

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
