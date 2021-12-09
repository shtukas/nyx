# encoding: UTF-8

$AFewNx50s = []

class AllTheNx50s
    # AllTheNx50s::setuuid()
    def self.setuuid()
        "catalyst:70853e76-3665-4b2a-8f1e-2f899a93ac06"
    end

    # AllTheNx50s::nx50s()
    def self.nx50s()
        ObjectStore4::getSet(AllTheNx50s::setuuid())
            .map{|nx50|
                if !Listings::listings().include?(nx50["listing"]) then
                    puts "Correcting listing for '#{nx50}'"
                    nx50["listing"] = Listings::interactivelySelectListing()
                    puts JSON.pretty_generate(nx50)
                    ObjectStore4::store(nx50, AllTheNx50s::setuuid())
                end
                nx50
            }
            .map{|nx50|
                if nx50["category2"].nil? or !Nx50s::coreCategories().include?(nx50["category2"][0]) then
                    puts JSON.pretty_generate(nx50)
                    nx50["category2"] = ["Dated", Utils::today()]
                    puts JSON.pretty_generate(nx50)
                    LucilleCore::pressEnterToContinue()
                    ObjectStore4::store(nx50, AllTheNx50s::setuuid())
                end
                nx50
            }
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
    end

    # AllTheNx50s::nx50sForListing(listing)
    def self.nx50sForListing(listing)
        AllTheNx50s::nx50s()
            .select{|nx50| nx50["listing"] == listing }
    end

end

class AFewNx50s

    # AFewNx50s::initialise(useTheForce)
    def self.initialise(useTheForce)

        if !useTheForce then
            nx50s = KeyValueStore::getOrNull(nil, "dd8f1ecc-c688-4b78-a77e-555c67186943")
            if nx50s then
                $AFewNx50s = JSON.parse(nx50s)
                return
            end
        end

        nx50s = []
        nx50s = nx50s + AllTheNx50s::nx50s().select{|item| item["category2"][0] == "Monitor" }
        nx50s = nx50s + AllTheNx50s::nx50s().select{|item| item["category2"][0] == "Dated" }
        Listings::listings().each{|listing|
            nx50s = nx50s + (AllTheNx50s::nx50sForListing(listing)
                                .select{|item| item["category2"][0] == "Tail" }
                                .reduce({"Nx50s"=>[], "counter"=>0}){|struct, nx50|
                                    if struct["counter"] < 20 then
                                        struct["Nx50s"] << nx50
                                        if Nx50s::itemIsOperational(nx50) then
                                            struct["counter"] = struct["counter"] + 1
                                        end
                                    end
                                    struct
                                })["Nx50s"]
        }
        $AFewNx50s = nx50s
        KeyValueStore::set(nil, "dd8f1ecc-c688-4b78-a77e-555c67186943", JSON.generate($AFewNx50s))
    end

    # AFewNx50s::getSet()
    def self.getSet()
        $AFewNx50s
            .map{|nx50| nx50.clone }
            .sort{|x1, x2| x1["ordinal"] <=> x2["ordinal"] }
    end

    # AFewNx50s::getSetForListing(listing)
    def self.getSetForListing(listing)
        AFewNx50s::getSet()
            .select{|item| item["listing"] == listing }
    end

    # AFewNx50s::commit(nx50)
    def self.commit(nx50)
        ObjectStore4::store(nx50, AllTheNx50s::setuuid())
        $AFewNx50s = ($AFewNx50s.reject{|x| x["uuid"] == nx50["uuid"] } + [ nx50.clone ])
        KeyValueStore::set(nil, "dd8f1ecc-c688-4b78-a77e-555c67186943", JSON.generate($AFewNx50s))
    end

    # AFewNx50s::destroy(nx50)
    def self.destroy(nx50)
        ObjectStore4::removeObjectFromSet(AllTheNx50s::setuuid(), nx50["uuid"])
        $AFewNx50s = $AFewNx50s.reject{|x| x["uuid"] == nx50["uuid"] }
        KeyValueStore::set(nil, "dd8f1ecc-c688-4b78-a77e-555c67186943", JSON.generate($AFewNx50s))
    end
end

class Nx50s

    # --------------------------------------------------
    # Ordinals

    # Nx50s::nextOrdinal()
    def self.nextOrdinal()
        biggest = ([0] + AllTheNx50s::nx50s().map{|nx50| nx50["ordinal"] }).max
        (biggest + 1).floor
    end

    # Nx50s::interactivelyDecideNewOrdinalOrNull(listing, category2)
    def self.interactivelyDecideNewOrdinalOrNull(listing, category2)
        if category2[0] == "Monitor" then
            return Nx50s::nextOrdinal()
        end
        if category2[0] == "Dated" then
            return Nx50s::nextOrdinal()
        end
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["fine selection near the top", "next"])
        return nil if action.nil?
        if action == "next" then
            return Nx50s::nextOrdinal()
        end
        if action == "fine selection near the top" then
            AFewNx50s::getSetForListing(listing)
                .first(50)
                .select{|item| item["category2"][0] == category2[0] }
                .each{|nx50| 
                    puts "- #{Nx50s::toStringWithOrdinal(nx50)}"
                }
            return LucilleCore::askQuestionAnswerAsString("> ordinal ? : ").to_f
        end
        raise "5fe95417-192b-4256-a021-447ba02be4aa"
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

    # Nx50s::makeNewInboxCategory2(listing)
    def self.makeNewInboxCategory2(listing)
        return ["Tail"] if listing == "ENTERTAINMENT"
        return ["Tail"] if listing == "JEDI"
        corecategory = Nx50s::interactivelySelectCoreCategory()
        if corecategory == "Dated" then
            return ["Dated", Utils::interactivelySelectADateOrNull() || Utils::today()]
        end
        [corecategory]
    end

    # --------------------------------------------------
    # Makers

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        listing = Listings::interactivelySelectListing()
        category2 = Nx50s::makeNewCategory2()
        ordinal = Nx50s::interactivelyDecideNewOrdinalOrNull(listing, category2)
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => atom,
            "listing"     => listing,
            "category2"   => category2
        }
        AFewNx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueItemWithCategoryLambda(lambda1)
    def self.issueItemWithCategoryLambda(lambda1)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        listing = Listings::interactivelySelectListing()
        category2 = lambda1.call()
        ordinal = Nx50s::interactivelyDecideNewOrdinalOrNull(listing, category2)
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => atom,
            "listing"     => listing,
            "category2"   => category2
        }
        AFewNx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueItemUsingLine(line)
    def self.issueItemUsingLine(line)
        uuid = SecureRandom.uuid
        listing = Listings::interactivelySelectListing()
        category2 = Nx50s::makeNewCategory2()
        ordinal = Nx50s::interactivelyDecideNewOrdinalOrNull(listing, category2)
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => line,
            "atom"        => CoreData5::issueDescriptionOnlyAtom(),
            "listing"     => listing,
            "category2"   => category2
        }
        AFewNx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueItemUsingLocation(location, listing)
    def self.issueItemUsingLocation(location, listing)
        uuid = SecureRandom.uuid
        category2 = Nx50s::makeNewCategory2()
        ordinal = Nx50s::interactivelyDecideNewOrdinalOrNull(listing, category2)
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => File.basename(location),
            "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
            "listing"     => listing,
            "category2"   => category2
        }
        AFewNx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueInboxItemUsingLocation(location, listing, description)
    def self.issueInboxItemUsingLocation(location, listing, description)
        uuid = SecureRandom.uuid
        category2 = Nx50s::makeNewInboxCategory2(listing)
        ordinal = Nx50s::interactivelyDecideNewOrdinalOrNull(listing, category2)
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
            "listing"     => listing,
            "category2"   => category2
        }
        AFewNx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueSpreadItem(location, description, listing, ordinal)
    def self.issueSpreadItem(location, description, listing, ordinal)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
            "listing"     => listing,
            "category2"   => ["Tail"]
        }
        AFewNx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => Nx50s::nextOrdinal(),
            "description" => url,
            "atom"        => CoreData5::issueUrlAtomUsingUrl(url),
            "listing"     => "EVA",
            "category2"   => ["Tail"]
        }
        AFewNx50s::commit(nx50)
        nx50
    end

    # --------------------------------------------------
    # toString

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        "[nx50] #{nx50["description"]} (#{nx50["atom"]["type"]})"
    end

    # Nx50s::toStringWithOrdinal(nx50)
    def self.toStringWithOrdinal(nx50)
        "[nx50] (ord: #{nx50["ordinal"]}) #{nx50["description"]} (#{nx50["atom"]["type"]})"
    end

    # Nx50s::toStringForNS19(nx50)
    def self.toStringForNS19(nx50)
        "[nx50] #{nx50["description"]}"
    end

    # Nx50s::toStringForNS16(nx50, rt)
    def self.toStringForNS16(nx50, rt)
        if nx50["category2"][0] == "Monitor" then
            return "#{nx50["description"]} (#{nx50["atom"]["type"]}) (#{nx50["listing"].downcase})"
        end
        if nx50["category2"][0] == "Dated" then
            return "[#{nx50["category2"][1]}] #{nx50["description"]} (#{nx50["atom"]["type"]}) (#{nx50["listing"].downcase})"
        end
        "[Nx50] (#{"%4.2f" % rt}) #{nx50["description"]} (#{nx50["atom"]["type"]}) (#{nx50["listing"].downcase})"
    end

    # --------------------------------------------------
    # Operations

    # Nx50s::complete(nx50)
    def self.complete(nx50)
        AFewNx50s::destroy(nx50)
    end

    # Nx50s::importspread()
    def self.importspread()
        locations = LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s Spread")
 
        if locations.size > 0 then

            puts "Starting to import spread (first item: #{locations.first})"

            listing = Listings::interactivelySelectListing()
 
            ordinals = Nx50s::items().map{|item| item["ordinal"] }
 
            if ordinals.size < 2 then
                start1 = ordinals.max + 1
                end1   = ordinals.max + 1 + locations.size
            else
                start1 = ordinals.min
                end1   = ordinals.max + 1
            end
 
            spread = end1 - start1
 
            step = spread.to_f/locations.size
 
            cursor = start1
 
            locations.each{|location|
                cursor = cursor + step
                puts "[quark] (#{cursor}) #{location}"
                Nx50s::issueSpreadItem(location, File.basename(location), listing, cursor)
                LucilleCore::removeFileSystemLocation(location)
            }
        end
    end

    # Nx50s::accessContent(nx50)
    def self.accessContent(nx50)
        updated = CoreData5::accessWithOptionToEdit(nx50["atom"])
        if updated then
            nx50["atom"] = updated
            AFewNx50s::commit(nx50)
        end
    end

    # Nx50s::run(nx50)
    def self.run(nx50)

        itemToBankAccounts = lambda{|item|
            accounts = []
            accounts << item["uuid"]
            accounts << Listings::listingToBankAccount(item["listing"])
            accounts.compact
        }

        system("clear")

        uuid = nx50["uuid"]

        NxBallsService::issue(uuid, nx50["description"], itemToBankAccounts.call(nx50))

        didItOnce1 = false

        loop {

            system("clear")

            puts "#{Nx50s::toString(nx50)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "ordinal: #{nx50["ordinal"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow
            puts "Listing: #{nx50["listing"]}".yellow
            puts "Category: #{nx50["category2"].join(", ")}".yellow

            if text = CoreData5::atomPayloadToTextOrNull(nx50["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(nx50["uuid"])
            if note then
                puts "note:\n#{note}".green
            end
            if nx50["atom"]["type"] != "description-only" and !didItOnce1 and LucilleCore::askQuestionAnswerAsBoolean("> access ? ", true) then
                Nx50s::accessContent(nx50)
            end
            didItOnce1 = true

            puts "access | note | <datecode> | description | atom | redate | ordinal | rotate | listing | category | show json | destroy (gg) | exit (xx)".yellow

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
                AFewNx50s::commit(nx50)
                next
            end

            if Interpreting::match("atom", command) then
                nx50["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                AFewNx50s::commit(nx50)
                next
            end

            if Interpreting::match("redate", command) then
                if nx50["category2"][0] == "Dated" then
                    nx50["category2"][1] = (Utils::interactivelySelectADateOrNull() || Utils::today())
                    AFewNx50s::commit(nx50)
                else
                    puts "You can only redate a dated item"
                    LucilleCore::pressEnterToContinue()
                end
                next
            end

            if Interpreting::match("ordinal", command) then
                ordinal = Nx50s::interactivelyDecideNewOrdinalOrNull(nx50["listing"])
                next if ordinal.nil?
                nx50["ordinal"] = ordinal
                AFewNx50s::commit(nx50)
                next
            end

            if Interpreting::match("rotate", command) then
                nx50["ordinal"] = Nx50s::nextOrdinal()
                AFewNx50s::commit(nx50)
                break
            end

            if Interpreting::match("listing", command) then
                listing = Listings::interactivelySelectListing()
                nx50["listing"] = listing
                nx50["ordinal"] = Nx50s::interactivelyDecideNewOrdinalOrNull(listing)
                AFewNx50s::commit(nx50)
                break
            end

            if Interpreting::match("category", command) then
                nx50["category2"] = Nx50s::makeNewCategory2()
                puts JSON.pretty_generate(nx50)
                AFewNx50s::commit(nx50)
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
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx50s::toString(nx50)}' ? ", true) then
                    Nx50s::complete(nx50)
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # Nx50s::itemIsOperational(item)
    def self.itemIsOperational(item)
        uuid = item["uuid"]
        return false if !DoNotShowUntil::isVisible(uuid)
        return false if !InternetStatus::ns16ShouldShow(uuid)
        true
    end

    # Nx50s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        getCommands = lambda{|nx50|
            if nx50["category2"][0] == "Dated" then
                return ["..", "redate", "done"]
            end
            ["..", "done"]
        }
        uuid = nx50["uuid"]
        return nil if !Nx50s::itemIsOperational(nx50)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        ns16 = {
            "uuid"     => uuid,
            "NS198"    => "ns16:Nx50",
            "announce" => Nx50s::toStringForNS16(nx50, rt),
            "commands" => getCommands.call(nx50),
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

        dated = mapping.keys.sort.map{|date| mapping[date].sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] } }.flatten

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

    # Nx50s::structureForListing(listing)
    def self.structureForListing(listing)
        Nx50s::structureGivenNx50s(AFewNx50s::getSetForListing(listing))
    end

    # --------------------------------------------------

    # Nx50s::nx19s()
    def self.nx19s()
        AllTheNx50s::nx50s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx50s::toStringForNS19(item),
                "lambda"   => lambda { Nx50s::run(item) }
            }
        }
    end
end
