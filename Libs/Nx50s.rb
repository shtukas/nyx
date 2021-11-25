# encoding: UTF-8

class Nx50s

    # Nx50s::setuuid()
    def self.setuuid()
        "catalyst:70853e76-3665-4b2a-8f1e-2f899a93ac06"
    end

    # Nx50s::nx50s()
    def self.nx50s()
        CoreData2::getSet(Nx50s::setuuid())
            .map{|atom|
                if !Domain::domains().include?(atom["domain"]) then
                    puts "Correcting domain for '#{Nx50s::toString(atom)}'"
                    atom["domain"] = Domain::interactivelySelectDomain()
                    puts JSON.pretty_generate(atom)
                    CoreData2::commitAtom2(atom)
                end
                atom
            }
            .map{|atom|
                if !Nx50s::coreCategories().include?(atom["category2"][0]) then
                    puts JSON.pretty_generate(atom)
                    raise "[error: af17a326-1637-473e-bc1b-ba53b4717591]"
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

    # --------------------------------------------------
    # Makers

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        atom = CoreData2::interactivelyCreateANewAtomOrNull([Nx50s::setuuid()])
        return nil if atom.nil?
        atom["unixtime"]  = Time.new.to_f
        atom["domain"]    = Domain::interactivelySelectDomain()
        atom["category2"] = Nx50s::makeNewCategory2Sequence()
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueItemUsingLine(line)
    def self.issueItemUsingLine(line)
        atom = CoreData2::issueDescriptionOnlyAtom(SecureRandom.uuid, description, [Nx50s::setuuid()])
        atom["unixtime"]  = Time.new.to_f
        atom["domain"]    = Domain::interactivelySelectDomain()
        atom["category2"] = Nx50s::makeNewCategory2Sequence()
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueItemUsingLocation(location, description, unixtime, domain)
    def self.issueItemUsingLocation(location, description, unixtime, domain)
        atom = CoreData2::issueAionPointAtomUsingLocation(SecureRandom.uuid, description, location, [Nx50s::setuuid()])
        atom["unixtime"]  = unixtime
        atom["domain"]    = domain
        atom["category2"] = Nx50s::makeNewCategory2Sequence()
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issuePriorityCommunicationItemUsingLocation(location, description, domain)
    def self.issuePriorityCommunicationItemUsingLocation(location, description, domain)
        atom = CoreData2::issueAionPointAtomUsingLocation(SecureRandom.uuid, description, location, [Nx50s::setuuid()])
        atom["unixtime"]  = Time.new.to_f
        atom["domain"]    = domain
        atom["category2"] = ["Priority Communication"]
        CoreData2::commitAtom2(atom)
    end

    # Nx50s::issueViennaURL(url)
    def self.issueViennaURL(url)
        atom = CoreData2::issueUrlAtomUsingUrl(SecureRandom.uuid, url, url, [Nx50s::setuuid()])
        atom["unixtime"]  = Time.new.to_f
        atom["domain"]    = "(eva)"
        atom["category2"] = ["Vienna"]
        CoreData2::commitAtom2(atom)
    end

    # --------------------------------------------------
    # Operations

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        "[nx50] (#{nx50["category2"][0].downcase}) #{CoreData2::toString(nx50)} (#{nx50["type"]})"
    end

    # Nx50s::toStringForNS19(atom)
    def self.toStringForNS19(atom)
        "[nx50] #{atom["description"]}"
    end

    # Nx50s::toStringForNS16(nx50, rt)
    def self.toStringForNS16(nx50, rt)

        mapping = {
            "Monitor"  => nil,
            "Priority Communication" => "(comm)".green,
            "Asap"     => "(asap)".green,
            "Quark"    => "(qurk)",
            "Vienna"   => "(vinn)",
            "Standard" => "(stnd)"
        }

       if nx50["category2"][0] == "Monitor" then
            nx50["description"]
       else
            "[nx50] (#{"%4.2f" % rt}) #{mapping[nx50["category2"][0]]} #{CoreData2::toString(nx50).gsub("[atom] ", "")} (#{nx50["type"]})"
       end
    end

    # Nx50s::complete(atom)
    def self.complete(atom)
        CoreData2::removeAtomFromSet(atom["uuid"], Nx50s::setuuid())
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
                Nx50s::issueItemUsingLocation(location, File.basename(location), cursor, "(eva)")
                LucilleCore::removeFileSystemLocation(location)
            }
        end
    end

    # --------------------------------------------------
    # Categories

    # Nx50s::coreCategories()
    def self.coreCategories()
        # "Priority Communication", "Asap" are in the order we want them to display
        ["Monitor", "Priority Communication", "Dated", "Asap", "Quark", "Vienna", "Standard"]
    end

    # Nx50s::timeTrackedCoreCategories()
    def self.timeTrackedCoreCategories()
        ["Quark", "Vienna", "Standard", "Asap"]
    end

    # Nx50s::nonTimeTrackedCoreCategories()
    def self.nonTimeTrackedCoreCategories()
        Nx50s::coreCategories() - Nx50s::timeTrackedCoreCategories()
    end

    # Nx50s::selectableCoreCategories()
    def self.selectableCoreCategories()
        ["Monitor", "Priority Communication", "Asap", "Standard"]
    end

    # Nx50s::coreCategoryToBankAccountOrNull(category)
    def self.coreCategoryToBankAccountOrNull(category)
        mapping = {
            "Quark"    => "9979D5C8-091D-4929-9E2E-2191FA1291B6",
            "Vienna"   => "35EFF9F7-1A58-48C4-B0CD-3499A0683A4D",
            "Standard" => "88245B96-DE84-4A4F-9F7B-50F7C907204C"
        }
        mapping[category]
    end

    # Nx50s::interactivelySelectCoreCategory()
    def self.interactivelySelectCoreCategory()
        category = LucilleCore::selectEntityFromListOfEntitiesOrNull("category", Nx50s::selectableCoreCategories())
        if !category.nil? then
            return category
        end
        Nx50s::interactivelySelectCoreCategory()
    end

    # Nx50s::makeNewCategory2Sequence()
    def self.makeNewCategory2Sequence()
        corecategory = Nx50s::interactivelySelectCoreCategory()

        if category == "Dated" then
            return ["Dated", Utils::interactivelySelectADateOrNull() || Utils::today()]
        end

        [corecategory]
    end

    # --------------------------------------------------
    # nx16s

    # Nx50s::run(nx50)
    def self.run(nx50)

        itemToBankAccounts = lambda{|item|
            accounts = []
            accounts << item["uuid"]
            accounts << Domain::domainToBankAccount(item["domain"])
            accounts << Nx50s::coreCategoryToBankAccountOrNull(item["category2"][0])
            accounts.compact
        }

        system("clear")

        uuid = nx50["uuid"]

        NxBallsService::issue(uuid, Nx50s::toString(nx50), itemToBankAccounts.call(nx50))

        loop {

            system("clear")

            puts "#{Nx50s::toString(nx50)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "coreDataId: #{nx50["coreDataId"]}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow
            puts "category: #{nx50["category2"].join(", ")}".yellow

            puts CoreData2::atomPayloadToText(nx50)

            note = StructuredTodoTexts::getNoteOrNull(nx50["uuid"])
            if note then
                puts "note:\n#{note}".green
            end

            puts "access | note | <datecode> | description | update contents | rotate | domain | category | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

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

            if Interpreting::match("description", command) then
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

            if Interpreting::match("category", command) then
                nx50["category2"] = Nx50s::makeNewCategory2Sequence()
                puts JSON.pretty_generate(nx50)
                CoreData2::commitAtom2(nx50)
                next
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

        NxBallsService::closeWithAsking(uuid)
    end

    # Nx50s::itemIsOperational(item)
    def self.itemIsOperational(item)
        uuid = item["uuid"]
        return false if !DoNotShowUntil::isVisible(uuid)
        return false if !InternetStatus::ns16ShouldShow(uuid)
        true
    end

    # Nx50s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        announceMake = lambda {|nx50, rt, tx|
            uuid = nx50["uuid"]
            note = StructuredTodoTexts::getNoteOrNull(uuid)
            noteStr = note ? " [note]" : ""
            if nx50["category2"][0] == "Monitor" then
                return "[#{Time.at(nx50["unixtime"]).to_s[0, 10]}] #{Nx50s::toStringForNS16(nx50, rt)}#{noteStr} (#{nx50["type"]})".strip
            end
            if nx50["category2"][0] == "Dated" then
                return "[#{nx50["category2"][1]}] #{Nx50s::toStringForNS16(nx50, rt)}#{noteStr} (#{nx50["type"]})".strip
            end
            "#{Nx50s::toStringForNS16(nx50, rt)}#{noteStr} (today: #{tx.round(2)}, rt: #{rt.round(2)})".gsub("(0.00)", "      ").gsub("(today: 0.0, rt: 0.0)", "").strip
        }

        uuid = nx50["uuid"]
        return nil if !Nx50s::itemIsOperational(nx50)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        tx = Bank::valueAtDate(uuid, Utils::today()).to_f/3600
        
        
        announce = announceMake.call(nx50, rt, tx)
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

    # Nx50s::ns16sX2(domain)
    def self.ns16sX2(domain)

        Nx50s::importspread()

        items = Nx50s::nx50sForDomain(domain)

        monitor, items = items.partition{|item| item["category2"][0] == "Monitor" }

        monitor = monitor
                    .map{|item| Nx50s::ns16OrNull(item) }
                    .compact

        dated, items = items.partition{|item| item["category2"][0] == "Dated" }

        dated = dated.select{|item| item["category2"][1] <= Utils::today()}

        mapping = dated
            .map{|atom|
                if atom["date"].nil? then
                    atom["date"] = Utils::today()
                end
                atom
            }
            .reduce({}){|mapping, atom|
                if mapping[atom["date"]].nil? then
                    mapping[atom["date"]] = []
                end
                mapping[atom["date"]] << atom
                mapping
            }

        dated = mapping.keys.sort.map{|date| mapping[date].sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] } }.flatten

        dated = dated
                    .map{|item| Nx50s::ns16OrNull(item) }
                    .compact

        items1 = items
            .select{|item| Nx50s::nonTimeTrackedCoreCategories().include?(item["category2"][0]) }
            .reduce([]){|selection, item|  
                if selection.size < 20 and Nx50s::itemIsOperational(item) then
                    selection << item
                end
                selection
            }

        items2 = Nx50s::timeTrackedCoreCategories()
                    .map{|category|
                        its = items
                                    .select{|item| item["category2"][0] == category }
                                    .reduce([]){|selection, item|  
                                        if selection.size < 10 and Nx50s::itemIsOperational(item) then
                                            selection << item
                                        end
                                        selection
                                    }
                        {
                            "items"      => its,
                            "categoryRT" => BankExtended::stdRecoveredDailyTimeInHours(Nx50s::coreCategoryToBankAccountOrNull(category)) 
                        }
                    }
                    .sort{|p1, p2| p1["categoryRT"] <=> p2["categoryRT"] }
                    .map{|packet| packet["items"] }
                    .flatten

        items = items1 + items2

        ns16s = items
                    .map{|item| Nx50s::ns16OrNull(item) }
                    .compact

        threshold = Nx50s::overflowThreshold(domain)
        overflow, tail = ns16s.partition{|ns16| Bank::valueAtDate(ns16["uuid"], Utils::today()).to_f/3600 > threshold }
        {
            "Monitor"  => monitor,
            "overflow" => overflow,
            "dated"    => dated,
            "tail"     => tail
        }
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
