# encoding: UTF-8

class TxTodos

    # TxTodos::items()
    def self.items()
        LibrarianObjects::getObjectsByMikuType("TxTodo")
    end

    # TxTodos::itemsCardinal(n)
    def self.itemsCardinal(n)
        LibrarianObjects::getObjectsByMikuTypeLimitByOrdinal("TxTodo", n)
    end

    # TxTodos::destroy(uuid)
    def self.destroy(uuid)
        LibrarianObjects::destroy(uuid)
    end

    # --------------------------------------------------
    # Ordinals

    # TxTodos::nextOrdinal()
    def self.nextOrdinal()
        biggest = ([0] + TxTodos::items().map{|nx50| nx50["ordinal"] }).max
        (biggest + 1).floor
    end

    # TxTodos::ordinalBetweenN1thAndN2th(n1, n2)
    def self.ordinalBetweenN1thAndN2th(n1, n2)
        nx50s = TxTodos::itemsCardinal(n2)
        if nx50s.size < n1+2 then
            return TxTodos::nextOrdinal()
        end
        ordinals = nx50s.map{|nx50| nx50["ordinal"] }.sort.drop(n1).take(n2-n1)
        ordinals.min + rand*(ordinals.max-ordinals.min)
    end

    # TxTodos::interactivelyDecideNewOrdinal()
    def self.interactivelyDecideNewOrdinal()
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["fine selection near the top", "random within [10-20] (default)"])
        if action == "fine selection near the top" then
            TxTodos::itemsCardinal(50)
                .each{|nx50| 
                    puts "- #{TxTodos::toStringWithOrdinal(nx50)}"
                }
            return LucilleCore::askQuestionAnswerAsString("> ordinal ? : ").to_f
        end
        if action.nil? or action == "random within [10-20] (default)" then
            return TxTodos::ordinalBetweenN1thAndN2th(10, 20)
        end
        raise "5fe95417-192b-4256-a021-447ba02be4aa"
    end

    # --------------------------------------------------
    # Makers

    # TxTodos::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom       = CoreData5::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        LibrarianObjects::commit(atom)

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        ordinal    = TxTodos::interactivelyDecideNewOrdinal()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "ordinal"     => ordinal
        }
        LibrarianObjects::commit(item)
        item
    end

    # TxTodos::issueItemUsingInboxLocation(location)
    def self.issueItemUsingInboxLocation(location)
        uuid = SecureRandom.uuid

        description = File.basename(location)
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601
        atom        = CoreData5::issueAionPointAtomUsingLocation(location)
        LibrarianObjects::commit(atom)
        ordinal     = TxTodos::ordinalBetweenN1thAndN2th(20, 30)

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "ordinal"     => ordinal
        }
        LibrarianObjects::commit(item)
        item
    end

    # TxTodos::interactivelyIssueItemUsingInboxLocation2(location)
    def self.interactivelyIssueItemUsingInboxLocation2(location)
        uuid        = SecureRandom.uuid
        description = Inbox::interactivelyDecideBestDescriptionForLocation(location)
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601
        atom        = CoreData5::issueAionPointAtomUsingLocation(location)
        LibrarianObjects::commit(atom)
        ordinal     = TxTodos::interactivelyDecideNewOrdinal()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "ordinal"     => ordinal
        }
        LibrarianObjects::commit(item)
        item
    end

    # TxTodos::issueSpreadItem(location, description, ordinal)
    def self.issueSpreadItem(location, description, ordinal)
        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        atom       = CoreData5::issueAionPointAtomUsingLocation(location)
        LibrarianObjects::commit(atom)
        ordinal    = ordinal

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "ordinal"     => ordinal
        }
        LibrarianObjects::commit(item)
        item
    end

    # TxTodos::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = url
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601
        atom        = CoreData5::issueUrlAtomUsingUrl(url)
        LibrarianObjects::commit(atom)
        ordinal     = TxTodos::ordinalBetweenN1thAndN2th(20, 30)

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "ordinal"     => ordinal
        }
        LibrarianObjects::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxTodos::toString(nx50)
    def self.toString(nx50)
        "[nx50] #{nx50["description"]}#{AgentsUtils::atomTypeForToStrings(" ", nx50["atomuuid"])}"
    end

    # TxTodos::toStringWithOrdinal(nx50)
    def self.toStringWithOrdinal(nx50)
        "[nx50] (ord: #{nx50["ordinal"]}) #{nx50["description"]}#{AgentsUtils::atomTypeForToStrings(" ", nx50["atomuuid"])}"
    end

    # TxTodos::toStringForNS16(nx50, rt)
    def self.toStringForNS16(nx50, rt)
        "[    ] (#{"%4.2f" % rt}) #{nx50["description"]}#{AgentsUtils::atomTypeForToStrings(" ", nx50["atomuuid"])}"
    end

    # TxTodos::toStringForNS19(nx50)
    def self.toStringForNS19(nx50)
        "[nx50] #{nx50["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxTodos::importspread()
    def self.importspread()
        locations = LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/TxTodos Spread")
 
        if locations.size > 0 then

            puts "Starting to import spread (first item: #{locations.first})"
 
            ordinals = TxTodos::items().map{|item| item["ordinal"] }
 
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
                TxTodos::issueSpreadItem(location, File.basename(location), cursor)
                LucilleCore::removeFileSystemLocation(location)
            }
        end
    end

    # TxTodos::run(nx50)
    def self.run(nx50)

        system("clear")

        uuid = nx50["uuid"]

        NxBallsService::issue(uuid, nx50["description"], [uuid])

        loop {

            system("clear")

            puts "#{TxTodos::toString(nx50)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "ordinal: #{nx50["ordinal"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            AgentsUtils::atomLandingPresentation(nx50["atomuuid"])

            #Librarian::notes(uuid).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | <datecode> | description | atom | ordinal | rotate | >> (transmute) | note | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                AgentsUtils::accessAtom(nx50["atomuuid"])
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(nx50["description"]).strip
                next if description == ""
                nx50["description"] = description
                LibrarianObjects::commit(nx50)
                next
            end

            if Interpreting::match("atom", command) then
                atom = CoreData5::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                atom["uuid"] = nx50["atomuuid"]
                LibrarianObjects::commit(atom)
                next
            end

            if Interpreting::match("note", command) then
                #text = Utils::editTextSynchronously("").strip
                #Librarian::addNote(nx50["uuid"], SecureRandom.uuid, Time.new.to_i, text)
                #next
            end

            if Interpreting::match("ordinal", command) then
                ordinal = TxTodos::interactivelyDecideNewOrdinal()
                nx50["ordinal"] = ordinal
                LibrarianObjects::commit(nx50)
                next
            end

            if Interpreting::match("rotate", command) then
                nx50["ordinal"] = TxTodos::nextOrdinal()
                LibrarianObjects::commit(nx50)
                break
            end

            if Interpreting::match(">>", command) then
                CommandsOps::transmutation2(nx50, "TxTodo")
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx50)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxTodos::toString(nx50)}' ? ", true) then
                    TxTodos::destroy(nx50["uuid"])
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxTodos::toString(nx50)}' ? ", true) then
                    TxTodos::destroy(nx50["uuid"])
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # TxTodos::itemIsOperational(item)
    def self.itemIsOperational(item)
        uuid = item["uuid"]
        return false if !DoNotShowUntil::isVisible(uuid)
        return false if !InternetStatus::ns16ShouldShow(uuid)
        true
    end

    # TxTodos::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        uuid = nx50["uuid"]
        return nil if !TxTodos::itemIsOperational(nx50)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:TxTodo",
            "announce" => TxTodos::toStringForNS16(nx50, rt).gsub("(0.00)", "      "),
            "commands" => ["..", "done"],
            "ordinal"  => nx50["ordinal"],
            "TxTodo"   => nx50,
            "rt"       => rt
        }
    end

    # TxTodos::ns16s()
    def self.ns16s()
        TxTodos::importspread()
        ns16s = TxTodos::itemsCardinal(50)
            .map{|item| TxTodos::ns16OrNull(item) }
            .compact

        p1 = ns16s
                .first(6)
                .sort{|x1, x2|
                    (x1["rt"] > 0 ? x1["rt"] : 0.25)  <=> (x2["rt"] > 0 ? x2["rt"] : 0.25)
                }
        p2 = ns16s.drop(6)
        p1 + p2
    end

    # --------------------------------------------------

    # TxTodos::nx19s()
    def self.nx19s()
        TxTodos::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxTodos::toStringForNS19(item),
                "lambda"   => lambda { TxTodos::run(item) }
            }
        }
    end
end
