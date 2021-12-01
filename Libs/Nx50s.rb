# encoding: UTF-8

class Nx50s

    # Nx50s::setuuid()
    def self.setuuid()
        "catalyst:70853e76-3665-4b2a-8f1e-2f899a93ac06"
    end

    # Nx50s::nx50s()
    def self.nx50s()
        ObjectStore4::getSet(Nx50s::setuuid())
            .map{|nx50|
                if !Listings::listings().include?(nx50["domain"]) then
                    puts "Correcting domain for '#{nx50}'"
                    nx50["domain"] = Listings::interactivelySelectListing()
                    puts JSON.pretty_generate(nx50)
                    ObjectStore4::store(nx50, Nx50s::setuuid())
                end
                nx50
            }
            .map{|nx50|
                if nx50["category2"].nil? or !Nx50s::coreCategories().include?(nx50["category2"][0]) then
                    puts JSON.pretty_generate(nx50)
                    nx50["category2"] = ["Dated", Utils::today()]
                    puts JSON.pretty_generate(nx50)
                    LucilleCore::pressEnterToContinue()
                    ObjectStore4::store(nx50, Nx50s::setuuid())
                end
                nx50
            }
            .map{|nx50|
                if nx50["atom"].nil? then
                    puts JSON.pretty_generate(nx50)
                    nx50["atom"] = CoreData5::issueDescriptionOnlyAtom()
                    puts JSON.pretty_generate(nx50)
                    LucilleCore::pressEnterToContinue()
                    ObjectStore4::store(nx50, Nx50s::setuuid())
                end
                nx50
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
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "atom"        => CoreData5::interactivelyCreateNewAtomOrNull(),
            "domain"      => Listings::interactivelySelectListing(),
            "category2"   => Nx50s::makeNewCategory2()
        }
        ObjectStore4::store(nx50, Nx50s::setuuid())
        nx50
    end

    # Nx50s::issueItemWithCategoryLambda(lambda1)
    def self.issueItemWithCategoryLambda(lambda1)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "atom"        => CoreData5::interactivelyCreateNewAtomOrNull(),
            "domain"      => Listings::interactivelySelectListing(),
            "category2"   => lambda1.call()
        }
        ObjectStore4::store(nx50, Nx50s::setuuid())
        nx50
    end

    # Nx50s::issueItemUsingLine(line)
    def self.issueItemUsingLine(line)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => line,
            "atom"        => CoreData5::issueDescriptionOnlyAtom(),
            "domain"      => Listings::interactivelySelectListing(),
            "category2"   => Nx50s::makeNewCategory2()
        }
        ObjectStore4::store(nx50, Nx50s::setuuid())
        nx50
    end

    # Nx50s::issueItemUsingLocation(location, domain)
    def self.issueItemUsingLocation(location, domain)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => File.basename(location),
            "atom"        => CoreData5::issueDescriptionOnlyAtom(),
            "domain"      => domain,
            "category2"   => Nx50s::makeNewCategory2()
        }
        ObjectStore4::store(nx50, Nx50s::setuuid())
        nx50
    end

    # Nx50s::issueInboxItemUsingLocation(location, domain, description)
    def self.issueInboxItemUsingLocation(location, domain, description)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "atom"        => CoreData5::issueDescriptionOnlyAtom(),
            "domain"      => domain,
            "category2"   => Nx50s::makeNewInboxCategory2(domain)
        }
        ObjectStore4::store(nx50, Nx50s::setuuid())
        nx50
    end

    # Nx50s::issueSpreadItem(location, description, unixtime)
    def self.issueSpreadItem(location, description, unixtime)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "atom"        => CoreData5::issueDescriptionOnlyAtom(),
            "domain"      => "(entertainment)",
            "category2"   => ["Tail"]
        }
        ObjectStore4::store(nx50, Nx50s::setuuid())
        nx50
    end

    # Nx50s::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => url,
            "atom"        => CoreData5::issueUrlAtomUsingUrl(url),
            "domain"      => "(eva)",
            "category2"   => ["Tail"]
        }
        ObjectStore4::store(nx50, Nx50s::setuuid())
        nx50
    end

    # --------------------------------------------------
    # Operations

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        "[nx50] #{nx50["description"]} (#{nx50["atom"]["type"]})"
    end

    # Nx50s::toStringForNS19(nx50)
    def self.toStringForNS19(nx50)
        "[nx50] #{nx50["description"]}"
    end

    # Nx50s::toStringForNS16(nx50, rt)
    def self.toStringForNS16(nx50, rt)
        if nx50["category2"][0] == "Monitor" then
            return "#{nx50["description"]} (#{nx50["atom"]["type"]}) #{nx50["domain"]}"
        end
        if nx50["category2"][0] == "Dated" then
            return "[#{nx50["category2"][1]}] #{nx50["description"]} (#{nx50["atom"]["type"]}) #{nx50["domain"]}"
        end
        "[Nx50] (#{"%4.2f" % rt}) #{nx50["description"]} (#{nx50["atom"]["type"]}) #{nx50["domain"]}"
    end

    # Nx50s::complete(nx50)
    def self.complete(nx50)
        ObjectStore4::removeObjectFromSet(Nx50s::setuuid(), nx50["uuid"])
        Mercury::postValue("A4EC3B4B-NATHALIE-COLLECTION-REMOVE", nx50["uuid"])
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
                Nx50s::issueSpreadItem(location, File.basename(location), cursor)
                LucilleCore::removeFileSystemLocation(location)
            }
        end
    end

    # Nx50s::accessContent(nx50)
    def self.accessContent(nx50)
        updated = CoreData5::accessWithOptionToEdit(nx50["atom"])
        if updated then
            nx50["atom"] = updated
            ObjectStore4::store(nx50, Nx50s::setuuid())
        end
    end

    # --------------------------------------------------
    # Categories

    # Nx50s::coreCategories()
    def self.coreCategories()
        ["Monitor", "Dated", "Tail"]
    end

    # Nx50s::interactivelySelectCoreCategory()
    def self.interactivelySelectCoreCategory()
        category = LucilleCore::selectEntityFromListOfEntitiesOrNull("category", Nx50s::coreCategories())
        if !category.nil? then
            return category
        end
        Nx50s::interactivelySelectCoreCategory()
    end

    # Nx50s::makeNewCategory2()
    def self.makeNewCategory2()
        corecategory = Nx50s::interactivelySelectCoreCategory()
        if corecategory == "Dated" then
            return ["Dated", Utils::interactivelySelectADateOrNull() || Utils::today()]
        end
        [corecategory]
    end

    # Nx50s::makeNewInboxCategory2(domain)
    def self.makeNewInboxCategory2(domain)
        return ["Tail"] if domain == "(entertainment)"
        return ["Tail"] if domain == "(jedi)"
        corecategory = Nx50s::interactivelySelectCoreCategory()
        if corecategory == "Dated" then
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
            accounts << Listings::listingToBankAccount(item["domain"])
            accounts.compact
        }

        system("clear")

        uuid = nx50["uuid"]

        NxBallsService::issue(uuid, Nx50s::toString(nx50), itemToBankAccounts.call(nx50))

        didItOnce1 = false

        loop {

            system("clear")

            puts "#{Nx50s::toString(nx50)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow
            puts "Domain: #{nx50["domain"]}".yellow
            puts "Category: #{nx50["category2"].join(", ")}".yellow

            puts CoreData5::atomPayloadToText(nx50["atom"])

            note = StructuredTodoTexts::getNoteOrNull(nx50["uuid"])
            if note then
                puts "note:\n#{note}".green
            end
            if nx50["atom"]["type"] != "description-only" and !didItOnce1 and LucilleCore::askQuestionAnswerAsBoolean("> access ? ", true) then
                Nx50s::accessContent(nx50)
            end
            didItOnce1 = true

            puts "access | note | <datecode> | description | update contents | rotate | domain | category | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Nx50s::accessContent(nx50)
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
                ObjectStore4::store(nx50, Nx50s::setuuid())
                next
            end

            if Interpreting::match("update contents", command) then
                nx50["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                ObjectStore4::store(nx50, Nx50s::setuuid())
                next
            end

            if Interpreting::match("rotate", command) then
                nx50["unixtime"] = Time.new.to_f
                ObjectStore4::store(nx50, Nx50s::setuuid())
                break
            end

            if Interpreting::match("domain", command) then
                nx50["domain"] = Listings::interactivelySelectListing()
                ObjectStore4::store(nx50, Nx50s::setuuid())
                break
            end

            if Interpreting::match("category", command) then
                nx50["category2"] = Nx50s::makeNewCategory2()
                puts JSON.pretty_generate(nx50)
                ObjectStore4::store(nx50, Nx50s::setuuid())
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
        Mercury::postValue("A4EC3B4B-NATHALIE-COLLECTION-REMOVE", nx50["uuid"])
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
        uuid = nx50["uuid"]
        return nil if !Nx50s::itemIsOperational(nx50)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        ns16 = {
            "uuid"     => uuid,
            "NS198"    => "ns16:Nx501",
            "announce" => Nx50s::toStringForNS16(nx50, rt),
            "commands" => ["..", "done"],
            "Nx50"     => nx50,
            "rt"       => rt
        }
        if Bank::valueAtDate(uuid, Utils::today()) > 3600  then
            ns16["announce"] = ns16["announce"].yellow
            ns16["defaultable"] = false
        end
        ns16
    end

    # Nx50s::structureGivenNx50s(items)
    def self.structureGivenNx50s(items)

        Nx50s::importspread()

        # -- monitor ---------------------------

        monitor, items = items.partition{|item| item["category2"][0] == "Monitor" }

        monitor = monitor
                    .map{|item| Nx50s::ns16OrNull(item) }
                    .compact

        # -- dated ---------------------------

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

        # -- tail ---------------------------

        tail = items
                .reduce([]){|selection, item|  
                    if selection.size < 100 and Nx50s::itemIsOperational(item) then
                        selection << item
                    end
                    selection
                }

        tail = tail
                .map{|item| Nx50s::ns16OrNull(item) }
                .compact

        # -- structure ---------------------------

        {
            "Monitor"  => monitor,
            "Dated"    => dated,
            "Tail"     => tail
        }
    end

    # Nx50s::structureForDomain(domain)
    def self.structureForDomain(domain)
        Nx50s::structureGivenNx50s(Nx50s::nx50sForDomain(domain))
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
