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
                if nx50["category2"].nil? or !Nx50s::coreCategories().include?(nx50["category2"][0]) then
                    puts JSON.pretty_generate(nx50)
                    nx50["category2"] = ["Dated", Utils::today()]
                    puts JSON.pretty_generate(nx50)
                    LucilleCore::pressEnterToContinue()
                    ObjectStore4::store(nx50, Nx50s::setuuid())
                end
                nx50
            }
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
    end

    # Nx50s::commit(nx50)
    def self.commit(nx50)
        if nx50["ordinal"].nil? then
            puts "Incorrect Nx50 trying to be commited"
            puts JSON.pretty_generate(nx50)
            exit
        end
        ObjectStore4::store(nx50, Nx50s::setuuid())
    end

    # Nx50s::destroy(nx50)
    def self.destroy(nx50)
        ObjectStore4::removeObjectFromSet(Nx50s::setuuid(), nx50["uuid"])
    end

    # --------------------------------------------------
    # Ordinals

    # Nx50s::nextOrdinal()
    def self.nextOrdinal()
        biggest = ([0] + Nx50s::nx50s().map{|nx50| nx50["ordinal"] }).max
        (biggest + 1).floor
    end

    # Nx50s::nextMonitorTodoOrdinal()
    def self.nextMonitorTodoOrdinal()
        nx50s = Nx50s::nx50s()
                    .select{|nx50| nx50["category2"][0] == "Monitor-Todo" }
        biggest = ([0] + nx50s.map{|nx50| nx50["ordinal"] }).max
        (biggest + 1).floor
    end

    # Nx50s::ordinalBetweenN1thAndN2th(n1, n2)
    def self.ordinalBetweenN1thAndN2th(n1, n2)
        nx50s = Nx50s::nx50s()
        if nx50s.size < n1+2 then
            return Nx50s::nextOrdinal()
        end
        ordinals = nx50s.map{|nx50| nx50["ordinal"] }.sort.drop(n1).take(n2-n1)
        ordinals.min + rand*(ordinals.max-ordinals.min)
    end

    # Nx50s::interactivelyDecideNewOrdinal(category2)
    def self.interactivelyDecideNewOrdinal(category2)
        if category2[0] == "Monitor" then
            return Nx50s::nextOrdinal()
        end
        if category2[0] == "Monitor-Todo" then
            return Nx50s::nextMonitorTodoOrdinal()
        end
        if category2[0] == "Dated" then
            return Nx50s::nextOrdinal()
        end
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["fine selection near the top", "random within [10-20] (default)"])
        if action == "fine selection near the top" then
            Nx50s::nx50s()
                .first(50)
                .select{|item| item["category2"][0] == category2[0] }
                .each{|nx50| 
                    puts "- #{Nx50s::toStringWithOrdinal(nx50)}"
                }
            return LucilleCore::askQuestionAnswerAsString("> ordinal ? : ").to_f
        end
        if action.nil? or action == "random within [10-20] (default)" then
            return Nx50s::ordinalBetweenN1thAndN2th(10, 20)
        end
        raise "5fe95417-192b-4256-a021-447ba02be4aa"
    end

    # --------------------------------------------------
    # Categories

    # Nx50s::coreCategories()
    def self.coreCategories()
        ["Monitor", "Monitor-Todo", "Dated", "Tail"]
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

    # Nx50s::makeNewInboxCategory2()
    def self.makeNewInboxCategory2()
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
        category2 = Nx50s::makeNewCategory2()
        ordinal = Nx50s::interactivelyDecideNewOrdinal(category2)
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => atom,
            "category2"   => category2
        }
        Nx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueItemWithCategoryLambdaOrNull(lambda1)
    def self.issueItemWithCategoryLambdaOrNull(lambda1)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        category2 = lambda1.call()
        ordinal = Nx50s::interactivelyDecideNewOrdinal(category2)
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => atom,
            "category2"   => category2
        }
        Nx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueItemUsingLine(line)
    def self.issueItemUsingLine(line)
        uuid = SecureRandom.uuid
        category2 = Nx50s::makeNewCategory2()
        ordinal = Nx50s::interactivelyDecideNewOrdinal(category2)
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => line,
            "atom"        => CoreData5::issueDescriptionOnlyAtom(),
            "category2"   => category2
        }
        Nx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueItemUsingLocation(location)
    def self.issueItemUsingLocation(location)
        uuid = SecureRandom.uuid
        category2 = Nx50s::makeNewCategory2()
        ordinal = Nx50s::interactivelyDecideNewOrdinal(category2)
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => File.basename(location),
            "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
            "category2"   => category2
        }
        Nx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueInboxItemUsingLocation(location, description)
    def self.issueInboxItemUsingLocation(location, description)
        uuid = SecureRandom.uuid
        category2 = Nx50s::makeNewInboxCategory2()
        ordinal = Nx50s::interactivelyDecideNewOrdinal(category2)
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
            "category2"   => category2
        }
        Nx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueSpreadItem(location, description, ordinal)
    def self.issueSpreadItem(location, description, ordinal)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
            "category2"   => ["Tail"]
        }
        Nx50s::commit(nx50)
        nx50
    end

    # Nx50s::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => Nx50s::ordinalBetweenN1thAndN2th(10, 50),
            "description" => url,
            "atom"        => CoreData5::issueUrlAtomUsingUrl(url),
            "category2"   => ["Tail"]
        }
        Nx50s::commit(nx50)
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
            return "#{nx50["description"]} (#{nx50["atom"]["type"]})"
        end
        if nx50["category2"][0] == "Dated" then
            return "[#{nx50["category2"][1]}] #{nx50["description"]} (#{nx50["atom"]["type"]})"
        end
        "[Nx50] (#{"%4.2f" % rt}) #{nx50["description"]} (#{nx50["atom"]["type"]})"
    end

    # --------------------------------------------------
    # Operations

    # Nx50s::complete(nx50)
    def self.complete(nx50)
        Nx50s::destroy(nx50)
    end

    # Nx50s::importspread()
    def self.importspread()
        locations = LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s Spread")
 
        if locations.size > 0 then

            puts "Starting to import spread (first item: #{locations.first})"
 
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
            Nx50s::commit(nx50)
        end
    end

    # Nx50s::run(nx50)
    def self.run(nx50)

        itemToBankAccounts = lambda{|item|
            accounts = []
            accounts << item["uuid"]
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

            puts "access | note | <datecode> | description | atom | redate | ordinal | rotate | category | show json | destroy (gg) | exit (xx)".yellow

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
                Nx50s::commit(nx50)
                next
            end

            if Interpreting::match("atom", command) then
                nx50["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                Nx50s::commit(nx50)
                next
            end

            if Interpreting::match("redate", command) then
                if nx50["category2"][0] == "Dated" then
                    nx50["category2"][1] = (Utils::interactivelySelectADateOrNull() || Utils::today())
                    Nx50s::commit(nx50)
                else
                    puts "You can only redate a dated item"
                    LucilleCore::pressEnterToContinue()
                end
                next
            end

            if Interpreting::match("ordinal", command) then
                ordinal = Nx50s::interactivelyDecideNewOrdinal(nx50["category2"])
                nx50["ordinal"] = ordinal
                Nx50s::commit(nx50)
                next
            end

            if Interpreting::match("rotate", command) then
                nx50["ordinal"] = Nx50s::nextOrdinal()
                Nx50s::commit(nx50)
                break
            end

            if Interpreting::match("category", command) then
                category2 = Nx50s::makeNewCategory2()
                nx50["category2"] = category2
                nx50["ordinal"]   = Nx50s::interactivelyDecideNewOrdinal(category2)
                puts JSON.pretty_generate(nx50)
                Nx50s::commit(nx50)
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
                return ["..", "redate", "recategory", "done"]
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
            "ordinal"  => nx50["ordinal"],
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

        monitor = items.select{|item| item["category2"][0] == "Monitor" or item["category2"][0] == "Monitor-Todo" } # We get Monitor and Monitor-Todo
        items   = items.reject{|item| item["category2"][0] == "Monitor" } # We take everything except "Monitor"

        monitor = monitor
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
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

    # Nx50s::structure()
    def self.structure()
        Nx50s::structureGivenNx50s(Nx50s::nx50s())
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
