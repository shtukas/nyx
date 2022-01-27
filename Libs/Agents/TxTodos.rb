# encoding: UTF-8

class TxTodos

    # TxTodos::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/TxTodos.sqlite"
    end

    # TxTodos::nx50s()
    def self.nx50s()
        db = SQLite3::Database.new(TxTodos::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx50s_ order by _ordinal_") do |row|
            object = {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"].to_f,
                "ordinal"     => row["_ordinal_"].to_f,
                "description" => row["_description_"],
                "atom"        => JSON.parse(row["_atom_"])
            }
            answer << object
        end
        db.close
        answer
    end

    # TxTodos::nx50sCardinal(n)
    def self.nx50sCardinal(n)
        db = SQLite3::Database.new(TxTodos::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx50s_ order by _ordinal_ limit ?", [n]) do |row|
            object = {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"].to_f,
                "ordinal"     => row["_ordinal_"].to_f,
                "description" => row["_description_"],
                "atom"        => JSON.parse(row["_atom_"])
            }
            answer << object
        end
        db.close
        answer
    end

    # TxTodos::commit(nx50)
    def self.commit(nx50)
        db = SQLite3::Database.new(TxTodos::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx50s_ where _uuid_=?", [nx50["uuid"]]
        db.execute "insert into _nx50s_ (_uuid_, _unixtime_, _ordinal_, _description_, _atom_) values (?, ?, ?, ?, ?)", [nx50["uuid"], nx50["unixtime"], nx50["ordinal"], nx50["description"], JSON.generate(nx50["atom"])]
        db.close
    end

    # TxTodos::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(TxTodos::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx50s_ where _uuid_=?", [uuid]
        db.close
    end

    # --------------------------------------------------
    # Ordinals

    # TxTodos::nextOrdinal()
    def self.nextOrdinal()
        biggest = ([0] + TxTodos::nx50s().map{|nx50| nx50["ordinal"] }).max
        (biggest + 1).floor
    end

    # TxTodos::ordinalBetweenN1thAndN2th(n1, n2)
    def self.ordinalBetweenN1thAndN2th(n1, n2)
        nx50s = TxTodos::nx50sCardinal(n2)
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
            TxTodos::nx50sCardinal(50)
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
        uuid = SecureRandom.uuid
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        ordinal = TxTodos::interactivelyDecideNewOrdinal()
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => atom
        }
        TxTodos::commit(nx50)
        nx50
    end

    # TxTodos::issueItemUsingInboxLocation(location)
    def self.issueItemUsingInboxLocation(location)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => TxTodos::ordinalBetweenN1thAndN2th(20, 30),
            "description" => File.basename(location),
            "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
        }
        TxTodos::commit(nx50)
        nx50
    end

    # TxTodos::issueSpreadItem(location, description, ordinal)
    def self.issueSpreadItem(location, description, ordinal)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
        }
        TxTodos::commit(nx50)
        nx50
    end

    # TxTodos::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid = SecureRandom.uuid
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => TxTodos::ordinalBetweenN1thAndN2th(10, 50),
            "description" => url,
            "atom"        => CoreData5::issueUrlAtomUsingUrl(url)
        }
        TxTodos::commit(nx50)
        nx50
    end

    # --------------------------------------------------
    # toString

    # TxTodos::toString(nx50)
    def self.toString(nx50)
        "[nx50] #{nx50["description"]} (#{nx50["atom"]["type"]})"
    end

    # TxTodos::toStringWithOrdinal(nx50)
    def self.toStringWithOrdinal(nx50)
        "[nx50] (ord: #{nx50["ordinal"]}) #{nx50["description"]} (#{nx50["atom"]["type"]})"
    end

    # TxTodos::toStringForNS19(nx50)
    def self.toStringForNS19(nx50)
        "[nx50] #{nx50["description"]}"
    end

    # TxTodos::toStringForNS16(nx50, rt)
    def self.toStringForNS16(nx50, rt)
        "[todo] (#{"%4.2f" % rt}) #{nx50["description"]} (#{nx50["atom"]["type"]})"
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

    # TxTodos::accessContent(nx50)
    def self.accessContent(nx50)
        updated = CoreData5::accessWithOptionToEdit(nx50["atom"])
        if updated then
            nx50["atom"] = updated
            TxTodos::commit(nx50)
        end
    end

    # TxTodos::run(nx50)
    def self.run(nx50)

        system("clear")

        uuid = nx50["uuid"]

        NxBallsService::issue(uuid, nx50["description"], [uuid, DomainsX::evaAccount()])

        loop {

            system("clear")

            puts "#{TxTodos::toString(nx50)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "ordinal: #{nx50["ordinal"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            if text = CoreData5::atomPayloadToTextOrNull(nx50["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(nx50["uuid"])
            if note then
                puts "note:\n#{note}".green
            end

            puts "access | note | <datecode> | description | atom | ordinal | rotate | >> (transmute) | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                TxTodos::accessContent(nx50)
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
                TxTodos::commit(nx50)
                next
            end

            if Interpreting::match("atom", command) then
                nx50["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                TxTodos::commit(nx50)
                next
            end

            if Interpreting::match("ordinal", command) then
                ordinal = TxTodos::interactivelyDecideNewOrdinal()
                nx50["ordinal"] = ordinal
                TxTodos::commit(nx50)
                next
            end

            if Interpreting::match("rotate", command) then
                nx50["ordinal"] = TxTodos::nextOrdinal()
                TxTodos::commit(nx50)
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
            "TxTodo"     => nx50,
            "rt"       => rt
        }
    end

    # TxTodos::ns16s()
    def self.ns16s()
        TxTodos::importspread()
        ns16s = TxTodos::nx50sCardinal(50)
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
        TxTodos::nx50s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxTodos::toStringForNS19(item),
                "lambda"   => lambda { TxTodos::run(item) }
            }
        }
    end
end
