# encoding: UTF-8

class TxTodos

    # TxTodos::items()
    def self.items()
        LibrarianObjects::getObjectsByMikuType("TxTodo")
    end

    # TxTodos::itemsForDomainsX(domainx)
    def self.itemsForDomainsX(domainx)
        TxTodos::items().select{|item| item["domainx"] == domainx }
    end

    # TxTodos::itemsCardinal(n)
    def self.itemsCardinal(n)
        LibrarianObjects::getObjectsByMikuTypeLimitByOrdinal("TxTodo", n)
    end

    # TxTodos::itemsForDomainsXWithCardinal(domainx, n)
    def self.itemsForDomainsXWithCardinal(domainx, n)
        TxTodos::itemsForDomainsX(domainx).first(n)
    end

    # TxTodos::destroy(uuid)
    def self.destroy(uuid)
        LibrarianObjects::destroy(uuid)
    end

    # --------------------------------------------------
    # Ordinals

    # TxTodos::nextOrdinal(domainx)
    def self.nextOrdinal(domainx)
        biggest = ([0] + TxTodos::itemsForDomainsX(domainx).map{|nx50| nx50["ordinal"] }).max
        (biggest + 1).floor
    end

    # TxTodos::ordinalBetweenN1thAndN2th(domainx, n1, n2)
    def self.ordinalBetweenN1thAndN2th(domainx, n1, n2)
        nx50s = TxTodos::itemsForDomainsXWithCardinal(domainx, n2)
        if nx50s.size < n1+2 then
            return TxTodos::nextOrdinal(domainx)
        end
        ordinals = nx50s.map{|nx50| nx50["ordinal"] }.sort.drop(n1).take(n2-n1)
        ordinals.min + rand*(ordinals.max-ordinals.min)
    end

    # TxTodos::interactivelyDecideNewOrdinal(domainx)
    def self.interactivelyDecideNewOrdinal(domainx)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["fine selection near the top", "random within [10-20] (default)"])
        if action == "fine selection near the top" then
            TxTodos::itemsForDomainsXWithCardinal(domainx, 50)
                .each{|nx50| 
                    puts "- #{TxTodos::toStringWithOrdinal(nx50)}"
                }
            return LucilleCore::askQuestionAnswerAsString("> ordinal ? : ").to_f
        end
        if action.nil? or action == "random within [10-20] (default)" then
            return TxTodos::ordinalBetweenN1thAndN2th(domainx, 10, 20)
        end
        raise "5fe95417-192b-4256-a021-447ba02be4aa"
    end

    # TxTodos::interactivelySelectDomainX()
    def self.interactivelySelectDomainX()
        domainx = LucilleCore::selectEntityFromListOfEntitiesOrNull("domainx", ["eva", "work"])
        return TxTodos::interactivelySelectDomainX() if domainx.nil?
        domainx
    end

    # --------------------------------------------------
    # DomainsX

    # TxTodos::interactivelySelectDomainXOrNull()
    def self.interactivelySelectDomainXOrNull()
        domainx = LucilleCore::selectEntityFromListOfEntitiesOrNull("domainx", ["eva", "work", "(null)"])
        return TxTodos::interactivelySelectDomainXOrNull() if domainx.nil?
        return nil if domainx == "(null)"
        domainx
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
        domainx    = TxTodos::interactivelySelectDomainX()
        ordinal    = TxTodos::interactivelyDecideNewOrdinal(domainx)

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "ordinal"     => ordinal,
          "domainx"     => domainx
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

        domainx     = TxTodos::interactivelySelectDomainX()
        ordinal     = TxTodos::interactivelyDecideNewOrdinal(domainx)

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "ordinal"     => ordinal,
          "domainx"     => domainx
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
          "ordinal"     => ordinal,
          "domainx"     => "eva"
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
        ordinal     = TxTodos::ordinalBetweenN1thAndN2th("eva", 20, 30)

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "ordinal"     => ordinal,
          "domainx"     => "eva"
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
        "[todo] (#{"%4.2f" % rt}) #{nx50["description"]}#{AgentsUtils::atomTypeForToStrings(" ", nx50["atomuuid"])} (#{nx50["domainx"]})"
    end

    # TxTodos::toStringForNS19(nx50)
    def self.toStringForNS19(nx50)
        "[nx50] #{nx50["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxTodos::importspread()
    # We are not running this automatically, we do manual runs from nslog 
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

    # TxTodos::importTxTodosRandom()
    def self.importTxTodosRandom()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/TxTodos (Random) [eva]")
            .map{|location|
                puts "Importing TxTodos (Random) [eva]: #{location}"

                uuid        = SecureRandom.uuid
                description = File.basename(location)
                unixtime    = Time.new.to_i
                datetime    = Time.new.utc.iso8601
                atom        = CoreData5::issueAionPointAtomUsingLocation(location)
                ordinal     = TxTodos::ordinalBetweenN1thAndN2th("eva", 30, 50)

                item = {
                  "uuid"        => uuid,
                  "mikuType"    => "TxTodo",
                  "description" => description,
                  "unixtime"    => unixtime,
                  "datetime"    => datetime,
                  "atomuuid"    => atom["uuid"],
                  "ordinal"     => ordinal,
                  "domainx"     => "eva"
                }
                LibrarianObjects::commit(item)

                LucilleCore::removeFileSystemLocation(location)
            }
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
            puts "domainx: #{nx50["domainx"]}".yellow
            puts "ordinal: #{nx50["ordinal"]}".yellow

            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            LibrarianNotes::getObjectNotes(uuid).each{|note|
                puts "note: #{note["text"]}"
            }

            AgentsUtils::atomLandingPresentation(nx50["atomuuid"])

            #Librarian::notes(uuid).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | <datecode> | description | atom | ordinal | rotate | transmute | note | show json | destroy (gg) | exit (xx)".yellow

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
                text = Utils::editTextSynchronously("").strip
                LibrarianNotes::addNote(nx50["uuid"], text)
                next
            end

            if Interpreting::match("ordinal", command) then
                domainx = TxTodos::interactivelySelectDomainX()
                ordinal = TxTodos::interactivelyDecideNewOrdinal(domainx)
                nx50["domainx"] = domainx
                nx50["ordinal"] = ordinal
                LibrarianObjects::commit(nx50)
                next
            end

            if Interpreting::match("rotate", command) then
                domainx = TxTodos::interactivelySelectDomainX()
                ordinal = TxTodos::nextOrdinal(domainx)
                nx50["domainx"] = domainx
                nx50["ordinal"] = ordinal
                LibrarianObjects::commit(nx50)
                break
            end

            if Interpreting::match("transmute", command) then
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

    # TxTodos::ns16(nx50)
    def self.ns16(nx50)
        uuid = nx50["uuid"]
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

    # TxTodos::personalAssistanteOperationalNS16OrNull(nx50)
    def self.personalAssistanteOperationalNS16OrNull(nx50)
        uuid = nx50["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        return nil if !InternetStatus::ns16ShouldShow(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        return nil if rt > 1
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
        TxTodos::itemsCardinal(50)
            .map{|item| TxTodos::ns16(item) }
    end

    # TxTodos::ns16sOverflowing()
    def self.ns16sOverflowing()
        TxTodos::itemsCardinal(50)
            .map{|item| TxTodos::ns16(item) }
            .select{|ns16| ns16["rt"] > 1 }
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
