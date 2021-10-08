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
                "uuid"         => row["_uuid_"],
                "unixtime"     => row["_unixtime_"],
                "description"  => row["_description_"],
                "axiomId"      => row["_axiomId_"],
                "domain"       => row["_domain_"],
            }
        end
        db.close
        answer
    end

    # Nx50s::nx50sForDomain(domain)
    def self.nx50sForDomain(domain)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _items_ where _domain_=? order by _unixtime_", [domain]) do |row|
            answer << {
                "uuid"         => row["_uuid_"],
                "unixtime"     => row["_unixtime_"],
                "description"  => row["_description_"],
                "axiomId"      => row["_axiomId_"],
                "domain"       => row["_domain_"],
            }
        end
        db.close
        answer
    end

    # Nx50s::commitNx50ToDatabase(item)
    def self.commitNx50ToDatabase(item)
        if !Domains::domains().include?(item["domain"]) then
            item["domain"] = "eva"
        end
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _items_ where _uuid_=?", [item["uuid"]]
        db.execute "insert into _items_ (_uuid_, _unixtime_, _description_, _axiomId_, _domain_) values (?,?,?,?,?)", [item["uuid"], item["unixtime"], item["description"], item["axiomId"], item["domain"]]
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
                "uuid"         => row["_uuid_"],
                "unixtime"     => row["_unixtime_"],
                "description"  => row["_description_"],
                "axiomId"      => row["_axiomId_"],
                "domain"       => row["_domain_"],
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

    # Nx50s::quarksFolderPath()
    def self.quarksFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/Nx50s-quarks"
    end

    # Nx50s::fsckNxAxiomes()
    def self.fsckNxAxiomes()
        Nx50s::nx50s().each{|nx50|
            puts Nx50s::toString(nx50)
            next if KeyValueStore::flagIsTrue(nil, "0d972dc0-14ed-46a7-9f15-9347a97e6a70:#{Utils::today()}:#{nx50["uuid"]}")
            status = NxQuarks::fsck(Nx50s::quarksFolderPath(), nx50["axiomId"])
            if status then 
                KeyValueStore::setFlagTrue(nil, "0d972dc0-14ed-46a7-9f15-9347a97e6a70:#{Utils::today()}:#{nx50["uuid"]}")
            else
                puts "[problem]".red
            end
        }
    end

    # Nx50s::setItemDomain(uuid, domain)
    def self.setItemDomain(uuid, domain)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "update _items_ set _domain_=? where _uuid_=?", [domain, uuid]
        db.commit 
        db.close

        # In case this had not been done, we also need to update the map in the primary domain store
        KeyValueStore::set("/Users/pascal/Galaxy/DataBank/Catalyst/Domains/KV-Store", uuid, domain)
    end

    # --------------------------------------------------
    # Makers

    # Nx50s::getUnixtimeInRange(domain, index1, index2)
    def self.getUnixtimeInRange(domain, index1, index2)
        items = Nx50s::nx50sForDomain(domain).drop(index1).take(index2-index1)
        if items.size == 0 then
            return Time.new.to_f
        end
        if items.size == 1 then
            return items[0]["unixtime"]
        end
        unixtime1 = items.first["unixtime"]
        unixtime2 = items.last["unixtime"]
        return unixtime1 + rand*(unixtime2-unixtime1)
    end

    # Nx50s::interactivelyDetermineNewItemUnixtimeManuallyPositionAtDomain(domain)
    def self.interactivelyDetermineNewItemUnixtimeManuallyPositionAtDomain(domain)
        system("clear")
        items = Nx50s::nx50sForDomain(domain).first(Utils::screenHeight()-3)
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

    # Nx50s::interactivelyDetermineNewItemUnixtimeAtWork()
    def self.interactivelyDetermineNewItemUnixtimeAtWork()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["manually position", "last (default)"])
        if type.nil? then
            return Time.new.to_f
        end
        if type == "manually position" then
            return Nx50s::interactivelyDetermineNewItemUnixtimeManuallyPositionAtDomain("work")
        end
        if type == "last" then
            return Time.new.to_f
        end
        raise "13a8d479-3d49-415e-8d75-7d0c5d5c695e"
    end

    # Nx50s::interactivelyDetermineNewItemUnixtime(domain)
    def self.interactivelyDetermineNewItemUnixtime(domain)
        if domain == "work" then
            return Nx50s::interactivelyDetermineNewItemUnixtimeAtWork()
        end

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["manually position", "in 20-50 range (default)", "last"])
        if type.nil? then
            return Nx50s::getUnixtimeInRange(domain, 20, 50)
        end
        if type == "manually position" then
            return Nx50s::interactivelyDetermineNewItemUnixtimeManuallyPositionAtDomain(domain)
        end
        if type == "in 20-50 range (default)" then
            return Nx50s::getUnixtimeInRange(domain, 20, 50)
        end
        if type == "last" then
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
        domain = Domains::interactivelySelectDomainOrNull() || "eva"
        axiomId = NxQuarks::interactivelyCreateNewAxiom_EchoIdOrNull(Nx50s::quarksFolderPath(), LucilleCore::timeStringL22())
        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "axiomId"     => axiomId,
        })

        Domains::setDomainForItem(uuid, domain)

        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50MidRangeUsingLine(line, domain)
    def self.issueNx50MidRangeUsingLine(line, domain)
        uuid         = LucilleCore::timeStringL22()
        unixtime     = Nx50s::getUnixtimeInRange(domain, 10, 20)
        description  = line
        axiomId      = nil
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "axiomId"     => axiomId,
        })
        Domains::setDomainForItem(uuid, domain)
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingText(text, unixtime, domain)
    def self.issueNx50UsingText(text, unixtime, domain)
        uuid         = LucilleCore::timeStringL22()
        description  = text.strip.lines.first.strip || "todo text @ #{Time.new.to_s}" 
        axiomId      = NxA001::make(Nx50s::quarksFolderPath(), LucilleCore::timeStringL22(), text)
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "axiomId"     => axiomId,
        })
        Domains::setDomainForItem(uuid, domain)
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingURL(url)
    def self.issueNx50UsingURL(url)
        uuid         = LucilleCore::timeStringL22()
        unixtime     = Nx50s::getUnixtimeInRange("eva", 10, 20)
        description  = url
        axiomId      = NxA002::make(Nx50s::quarksFolderPath(), LucilleCore::timeStringL22(), url)
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "axiomId"     => axiomId,
        })
        Domains::setDomainForItem(uuid, "eva")
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingLocation(location)
    def self.issueNx50UsingLocation(location)
        uuid        = LucilleCore::timeStringL22()
        unixtime    = Nx50s::getUnixtimeInRange("eva", 20, 50)
        description = File.basename(location)
        axiomId     = NxA003::make(Nx50s::quarksFolderPath(), LucilleCore::timeStringL22(), location)
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "axiomId"     => axiomId,
        })
        Domains::setDomainForItem(uuid, "eva")
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
        type1 = NxQuarks::contentTypeOrNull(Nx50s::quarksFolderPath(), item["axiomId"])
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
        NxQuarks::destroy(Nx50s::quarksFolderPath(), nx50["axiomId"]) # function accepts null ids
        Nx50s::delete(nx50["uuid"])
    end

    # Nx50s::accessContent(item)
    def self.accessContent(item)
        if item["axiomId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        NxQuarks::accessWithOptionToEdit(Nx50s::quarksFolderPath(), item["axiomId"])
    end

    # Nx50s::accessContentsIfContents(nx50)
    def self.accessContentsIfContents(nx50)
        return if nx50["axiomId"].nil?
        NxQuarks::accessWithOptionToEdit(Nx50s::quarksFolderPath(), nx50["axiomId"])
    end

    # --------------------------------------------------
    # nx16s

    # Nx50s::run(nx50)
    def self.run(nx50)

        system("clear")

        uuid = nx50["uuid"]
        puts "#{Nx50s::toString(nx50)}".green
        puts "Starting at #{Time.new.to_s}"

        domain = Domains::interactivelyGetDomainForItemOrNull(uuid, Nx50s::toString(nx50))
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

        Nx50s::accessContentsIfContents(nx50)

        loop {

            system("clear")

            puts "#{Nx50s::toString(nx50)} (#{NxBalls::runningTimeString(nxball)})".green
            puts "uuid: #{uuid}".yellow
            puts "axiomId: #{nx50["axiomId"]}".yellow
            puts "NxAxiom fsck: #{NxQuarks::fsck(Nx50s::quarksFolderPath(), nx50["axiomId"])}".yellow
            puts "domain: #{nx50["domain"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow

            note = StructuredTodoTexts::getNoteOrNull(uuid)
            if note then
                puts "Note ---------------------"
                puts note.green
                puts "--------------------------"
            end

            puts "access | note | [] | <datecode> | detach running | pause | pursue | update description | update contents | update unixtime | set domain | show json | destroy | exit".yellow

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
                nx50["unixtime"] = Nx50s::interactivelyDetermineNewItemUnixtime(nx50["domain"])
                Nx50s::commitNx50ToDatabase(nx50)
                next
            end

            if Interpreting::match("set domain", command) then
                domain = Domains::interactivelySelectDomainOrNull()
                return if domain.nil?
                Domains::setDomainForItem(nx50["uuid"], domain)
                nx50["domain"] = domain
                Nx50s::commitNx50ToDatabase(nx50)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx50)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("detroy '#{Nx50s::toString(nx50)}' ? ", true) then
                    Nx50s::complete(nx50)
                    break
                end
                next
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Nx50s::ns16OrNull(nx50, showAboveRTOne)
    def self.ns16OrNull(nx50, showAboveRTOne)
        uuid = nx50["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        return nil if !InternetStatus::ns16ShouldShow(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        return nil if (!showAboveRTOne and (rt > 1))
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx50s::toStringForNS16(nx50, rt)}#{noteStr} (rt: #{rt.round(2)})".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "domain"   => nx50["domain"],
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
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Nx50s (Eva Inbox)").each{|location|
            puts "[inbox] #{location}"
            Nx50s::issueNx50UsingLocation(location)
            LucilleCore::removeFileSystemLocation(location)
            sleep 1
        }

        domain = Domains::getCurrentActiveDomain()
        showAboveRTOne = domain == "work"
        cardinal = (domain == "eva" ? 5 : nil)
        
        ns16s = Nx50s::nx50sForDomain(domain)
            .reduce([]){|object, nx50|
                if cardinal.nil? or object.size < cardinal then
                    ns16 = Nx50s::ns16OrNull(nx50, showAboveRTOne)
                    if ns16 then
                        object << ns16
                    end
                end
                object
            }

        if domain == "work" then
            x1, x2 = (ns16s + Work::interestNS16s())
                        .partition{|ns16|
                            ns16["rt"].nil? or ns16["rt"] < 1
                        }
            ns16s = x1.sort{|o1, o2| o1["unixtime-bd06fbf9"] <=> o2["unixtime-bd06fbf9"] } + x2.sort{|o1, o2| o1["rt"] <=> o2["rt"] }
        end

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
