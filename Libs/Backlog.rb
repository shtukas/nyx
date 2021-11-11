# encoding: UTF-8

class Backlog

    # Backlog::databaseFilepath2()
    def self.databaseFilepath2()
        "#{Utils::catalystDataCenterFolderpath()}/Items/backlog.sqlite3"
    end

    # Backlog::items()
    def self.items()
        db = SQLite3::Database.new(Backlog::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _items_ order by _unixtime_") do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "coreDataId"  => row["_coreDataId_"],
                "domain"      => row["_domain_"]
            }
        end
        db.close
        answer
    end

    # Backlog::itemsForDomain(domain)
    def self.itemsForDomain(domain)
        db = SQLite3::Database.new(Backlog::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _items_ where _domain_=? order by _unixtime_", [domain]) do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "coreDataId"  => row["_coreDataId_"],
                "domain"      => row["_domain_"]
            }
        end
        db.close
        answer
    end

    # Backlog::commitItemToDatabase(item)
    def self.commitItemToDatabase(item)
        db = SQLite3::Database.new(Backlog::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _items_ where _uuid_=?", [item["uuid"]]
        db.execute "insert into _items_ (_uuid_, _unixtime_, _description_, _coreDataId_, _domain_) values (?,?,?,?,?)", [item["uuid"], item["unixtime"], item["description"], item["coreDataId"], item["domain"]]
        db.commit 
        db.close
    end

    # Backlog::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Backlog::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        item = nil
        db.execute( "select * from _items_ where _uuid_=?" , [uuid] ) do |row|
            item = {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "coreDataId"  => row["_coreDataId_"],
                "domain"      => row["_domain_"]
            }
        end
        db.close
        item
    end

    # Backlog::delete(uuid)
    def self.delete(uuid)
        db = SQLite3::Database.new(Backlog::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _items_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # --------------------------------------------------
    # Operations

    # Backlog::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(Backlog::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "update _items_ set _description_=? where _uuid_=?", [description, uuid]
        db.commit 
        db.close
    end

    # Backlog::getItemType(item)
    def self.getItemType(item)
        type = KeyValueStore::getOrNull(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc77:#{item["coreDataId"]}")
        return type if type
        type1 = CoreData::contentTypeOrNull(item["coreDataId"])
        type2 = type1 || "line"
        KeyValueStore::set(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc77:#{item["coreDataId"]}", type2)
        type2
    end

    # Backlog::toString(item)
    def self.toString(item)
        "[bckl] #{item["description"]} (#{Backlog::getItemType(item)})"
    end

    # Backlog::toStringForNS19(item)
    def self.toStringForNS19(item)
        "[bckl] #{item["description"]}"
    end

    # Backlog::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        "[bckl] (#{"%4.2f" % rt}) #{item["description"]} (#{Backlog::getItemType(item)})"
    end

    # Backlog::complete(item)
    def self.complete(item)
        Backlog::delete(item["uuid"])
        Nx50DoneCounter::increaseTodayCount()
    end

    # Backlog::accessContent(item)
    def self.accessContent(item)
        if item["coreDataId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        CoreData::accessWithOptionToEdit(item["coreDataId"])
    end

    # --------------------------------------------------
    # nx16s

    # Backlog::run(item)
    def self.run(item)

        system("clear")

        uuid = item["uuid"]
        puts "#{Backlog::toString(item)}".green
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid, Domain::getDomainBankAccount(item["domain"])])

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

            puts "#{Backlog::toString(item)} (#{NxBalls::runningTimeString(nxball)})".green
            puts "uuid: #{uuid}".yellow
            puts "coreDataId: #{item["coreDataId"]}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow

            puts ""
            puts CoreData::toTextOrNull(item["coreDataId"])
            puts ""

            note = StructuredTodoTexts::getNoteOrNull(uuid)
            if note then
                puts "-- Note ------------------"
                puts note.green
                puts "--------------------------"
            end

            puts "access | note | [] | <datecode> | detach running | pause | pursue | update description | update contents | update unixtime | domain | show json | destroy (gg) | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Backlog::accessContent(item)
                next
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(item["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                note = StructuredTodoTexts::getNoteOrNull(uuid)
                if note then
                    puts "Note ---------------------"
                    puts note.green
                    puts "--------------------------"
                end
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Backlog::toString(item), Time.new.to_i, [uuid])
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
                description = Utils::editTextSynchronously(item["description"]).strip
                if description.size > 0 then
                    Backlog::updateDescription(item["uuid"], description)
                    item = Backlog::getItemByUUIDOrNull(item["uuid"])
                end
                next
            end

            if Interpreting::match("update contents", command) then
                coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()
                return if coreDataId.nil?
                item["coreDataId"] = coreDataId
                Backlog::commitItemToDatabase(item)
                next
            end

            if Interpreting::match("update unixtime", command) then
                domain = item["domain"]
                item["unixtime"] = Backlog::interactivelyDetermineNewItemUnixtime(domain)
                Backlog::commitItemToDatabase(item)
                next
            end

            if Interpreting::match("domain", command) then
                item["domain"] = Domain::interactivelySelectDomain()
                Backlog::commitItemToDatabase(item)
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Backlog::toString(item)}' ? ", true) then
                    Backlog::complete(item)
                    break
                end
                next
            end

            if command == "gg" then
                Backlog::complete(item)
                break
            end

        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Backlog::ns16OrNull(item)
    def self.ns16OrNull(item)
        uuid = item["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        return nil if !InternetStatus::ns16ShouldShow(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Backlog::toStringForNS16(item, rt)}#{noteStr} (rt: #{rt.round(2)})".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Backlog::run(item)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Backlog::toString(item)}' ? ", true) then
                        Backlog::complete(item)
                    end
                end
            },
            "run" => lambda {
                Backlog::run(item)
            },
            "rt" => rt
        }
    end

    # Backlog::ns16s(domain)
    def self.ns16s(domain)
        Backlog::itemsForDomain(domain)
            .map{|item| Backlog::ns16OrNull(item) }
            .compact
    end

    # --------------------------------------------------

    # Backlog::nx19s()
    def self.nx19s()
        Backlog::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Backlog::toStringForNS19(item),
                "lambda"   => lambda { Backlog::run(item) }
            }
        }
    end
end
