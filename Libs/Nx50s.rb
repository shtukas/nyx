# encoding: UTF-8

class Nx50s

    # Nx50s::databaseFilepath2()
    def self.databaseFilepath2()
        "#{Utils::catalystDataCenterFolderpath()}/items/Nx50s.sqlite3"
    end

    # Nx50s::nx50s()
    def self.nx50s()
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _items_ order by _unixtime_") do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "coreDataId"  => row["_coreDataId_"]
            }
        end
        db.close
        answer
    end

    # Nx50s::commitNx50ToDatabase(item)
    def self.commitNx50ToDatabase(item)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _items_ where _uuid_=?", [item["uuid"]]
        db.execute "insert into _items_ (_uuid_, _unixtime_, _description_, _coreDataId_) values (?,?,?,?)", [item["uuid"], item["unixtime"], item["description"], item["coreDataId"]]
        db.commit 
        db.close
    end

    # Nx50s::getNx50ByUUIDOrNull(uuid)
    def self.getNx50ByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        item = nil
        db.execute( "select * from _items_ where _uuid_=?" , [uuid] ) do |row|
            item = {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "coreDataId"  => row["_coreDataId_"]
            }
        end
        db.close
        item
    end

    # Nx50s::delete(uuid)
    def self.delete(uuid)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _items_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # --------------------------------------------------
    # Makers

    # Nx50s::interactivelyDetermineNewItemUnixtimeManuallyPosition()
    def self.interactivelyDetermineNewItemUnixtimeManuallyPosition()
        system("clear")
        items = Nx50s::nx50s().first(Utils::screenHeight()-3)
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

    # Nx50s::interactivelyDetermineNewItemUnixtime()
    def self.interactivelyDetermineNewItemUnixtime()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["manually position", "last (default)"])
        if type.nil? then
            return Time.new.to_f
        end
        if type == "manually position" then
            return Nx50s::interactivelyDetermineNewItemUnixtimeManuallyPosition()
        end
        if type == "last (default)" then
            return Time.new.to_f
        end
        raise "13a8d479-3d49-415e-8d75-7d0c5d5c695e"
    end

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = LucilleCore::timeStringL22()
        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end
        coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()
        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime()
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
        })
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueItemUsingText(text, unixtime)
    def self.issueItemUsingText(text, unixtime)
        uuid         = LucilleCore::timeStringL22()
        description  = text.strip.lines.first.strip || "todo text @ #{Time.new.to_s}" 
        coreDataId      = CoreData::issueTextDataObjectUsingText(text)
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
        })
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueItemUsingLocation(location, unixtime)
    def self.issueItemUsingLocation(location, unixtime)
        uuid        = LucilleCore::timeStringL22()
        description = File.basename(location)
        coreDataId = CoreData::issueAionPointDataObjectUsingLocation(location)
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
        })
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # --------------------------------------------------
    # Operations

    # Nx50s::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "update _items_ set _description_=? where _uuid_=?", [description, uuid]
        db.commit 
        db.close
    end

    # Nx50s::getItemType(item)
    def self.getItemType(item)
        type = KeyValueStore::getOrNull(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc77:#{item["uuid"]}")
        return type if type
        type1 = CoreData::contentTypeOrNull(item["coreDataId"])
        type2 = type1 || "line"
        KeyValueStore::set(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc77:#{item["uuid"]}", type2)
        type2
    end

    # Nx50s::toString(item)
    def self.toString(item)
        "[nx50] #{item["description"]} (#{Nx50s::getItemType(item)})"
    end

    # Nx50s::toStringForNS19(item)
    def self.toStringForNS19(item)
        "[nx50] #{item["description"]}"
    end

    # Nx50s::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        "[nx50] (#{"%4.2f" % rt}) #{item["description"]} (#{Nx50s::getItemType(item)})"
    end

    # Nx50s::complete(nx50)
    def self.complete(nx50)
        Nx50s::delete(nx50["uuid"])
    end

    # Nx50s::accessContent(item)
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

    # Nx50s::run(nx50)
    def self.run(nx50)

        system("clear")

        uuid = nx50["uuid"]
        puts "#{Nx50s::toString(nx50)}".green
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid])

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

        note = StructuredTodoTexts::getNoteOrNull(uuid)
        if note then
            puts "Note ---------------------"
            puts note.green
            puts "--------------------------"
        end

        Nx50s::accessContent(nx50)

        loop {

            system("clear")

            puts "#{Nx50s::toString(nx50)} (#{NxBalls::runningTimeString(nxball)})".green
            puts "uuid: #{uuid}".yellow
            puts "coreDataId: #{nx50["coreDataId"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow

            note = StructuredTodoTexts::getNoteOrNull(uuid)
            if note then
                puts "Note ---------------------"
                puts note.green
                puts "--------------------------"
            end

            puts "access | note | [] | <datecode> | detach running | pause | pursue | update description | update contents | update unixtime | show json | destroy | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

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
                DetachedRunning::issueNew2(Nx50s::toString(nx50), Time.new.to_i, [uuid])
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
                description = Utils::editTextSynchronously(nx50["description"]).strip
                if description.size > 0 then
                    Nx50s::updateDescription(nx50["uuid"], description)
                    nx50 = Nx50s::getNx50ByUUIDOrNull(nx50["uuid"])
                end
                next
            end

            if Interpreting::match("update contents", command) then
                puts "update contents against the new NxAxiom library is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("update unixtime", command) then
                nx50["unixtime"] = Nx50s::interactivelyDetermineNewItemUnixtime()
                Nx50s::commitNx50ToDatabase(nx50)
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
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Nx50s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        uuid = nx50["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        return nil if !InternetStatus::ns16ShouldShow(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx50s::toStringForNS16(nx50, rt)}#{noteStr} (rt: #{rt.round(2)})".gsub("(0.00)", "      ")
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
            "run" => lambda {
                Nx50s::run(nx50)
            },
            "rt" => rt,
            "unixtime-bd06fbf9" => nx50["unixtime"]
        }
    end

    # Nx50s::ns16s()
    def self.ns16s()

        locations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop/The End Of The Queue (Nx50s)")

        if locations.size > 0 then

            unixtimes = Nx50s::nx50s().map{|item| item["unixtime"] }

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

            #puts "Nx50 Inbox"
            #puts "  start : #{Time.at(start1).to_s} (#{start1})"
            #puts "  end   : #{Time.at(end1).to_s} (#{end1})"
            #puts "  spread: #{spread}"
            #puts "  step  : #{step}"

            locations.each{|location|
                cursor = cursor + step
                puts "[Nx50] (#{Time.at(cursor).to_s}) #{location}"
                Nx50s::issueItemUsingLocation(location, cursor)
                LucilleCore::removeFileSystemLocation(location)
            }
        end

        if !(Waves::ns16sWithCircuitBreaker()+Nx25s::ns16s()).empty? then
            return []
        end

        ns16s = Nx50s::nx50s()
            .reduce([]){|object, nx50|
                if object.size < 5 then
                    ns16 = Nx50s::ns16OrNull(nx50)
                    if ns16 then
                        object << ns16
                    end
                end
                object
            }
        ns16s
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
