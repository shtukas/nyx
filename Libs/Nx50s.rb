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
        db.execute "insert into _items_ (_uuid_, _unixtime_, _description_, _axiomId_) values (?,?,?,?)", [item["uuid"], item["unixtime"], item["description"], item["axiomId"]]
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

    # Nx50s::axiomsFolderPath()
    def self.axiomsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/Nx50s-axioms"
    end

    # Nx50s::fsckNxAxiomes()
    def self.fsckNxAxiomes()
        Nx50s::nx50s().each{|nx50|
            puts Nx50s::toString(nx50)
            next if KeyValueStore::flagIsTrue(nil, "0d972dc0-14ed-46a7-9f15-9347a97e6a70:#{Utils::today()}:#{nx50["uuid"]}")
            status = NxAxioms::fsck(Nx50s::axiomsFolderPath(), nx50["axiomId"])
            if status then 
                KeyValueStore::setFlagTrue(nil, "0d972dc0-14ed-46a7-9f15-9347a97e6a70:#{Utils::today()}:#{nx50["uuid"]}")
            else
                puts "[problem]".red
            end
        }
    end

    # --------------------------------------------------
    # Next Gen

    # Nx50s::getNextGenUUIDS()
    def self.getNextGenUUIDS()
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "3a249511-086b-4160-b33d-28550eb77114", "[]"))
    end

    # Nx50s::addToNextGenUUIDs(uuid)
    def self.addToNextGenUUIDs(uuid)
        uuids = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "3a249511-086b-4160-b33d-28550eb77114", "[]")) + [uuid]
        uuids = uuids & Nx50s::nx50s().map{|i| i["uuid"] }
        KeyValueStore::set(nil, "3a249511-086b-4160-b33d-28550eb77114", JSON.generate(uuids))
    end

    # Nx50s::getNextGenUnixtime()
    def self.getNextGenUnixtime()
        nexGenUUIDs = Nx50s::getNextGenUUIDS()
        nx50s = Nx50s::nx50s()
        while nx50s.any?{|nx50| nexGenUUIDs.include?(nx50["uuid"]) } do
            nx50s = nx50s.drop(1)
        end
        if nx50s.size < 2 then
            return Time.new.to_f
        end
        (nx50s[0]["unixtime"] + nx50s[1]["unixtime"]).to_f/2
    end

    # Nx50s::interactivelyDetermineNewItemUnixtime()
    def self.interactivelyDetermineNewItemUnixtime()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["select", "natural (default)"])
        if type.nil? then
            return Nx50s::getNextGenUnixtime()
        end
        if type == "natural (default)" then
            return Nx50s::getNextGenUnixtime()
        end
        if type == "select" then
            items = Nx50s::nx50s().first(50)
            return Nx50s::getNextGenUnixtime() if items.size < 2
            system('clear')
            puts "Select the before item:"
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Nx50s::toString(item) })
            if item.nil? then
                return Time.new.to_f
            end
            while items.any?{|i| i["uuid"] == item["uuid"] } do
                items = items.drop(1)
            end
            if items.size < 2 then
                return Time.new.to_f
            end
            return (items[0]["unixtime"]+items[1]["unixtime"]).to_f/2
        end
        raise "13a8d479-3d49-415e-8d75-7d0c5d5c695e"
    end

    # Nx50s::determineItemPositionOrNull(nx50)
    def self.determineItemPositionOrNull(nx50)
        Nx50s::nx50s().map{|i| i["uuid"] }.index(nx50["uuid"])
    end

    # --------------------------------------------------
    # Makers

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = LucilleCore::timeStringL22()
        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end
        axiomId = NxAxioms::interactivelyCreateNewAxiom_EchoIdOrNull(Nx50s::axiomsFolderPath(), LucilleCore::timeStringL22())
        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime()
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "axiomId"     => axiomId,
        })
        Nx50s::addToNextGenUUIDs(uuid)

        Domains::setDomainForItem(uuid, Domains::interactivelySelectDomainOrNull())

        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingLocation(location)
    def self.issueNx50UsingLocation(location)
        uuid        = LucilleCore::timeStringL22()
        unixtime    = Nx50s::getNextGenUnixtime()
        description = File.basename(location)
        axiomId     = NxA003::make(Nx50s::axiomsFolderPath(), LucilleCore::timeStringL22(), location)
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "axiomId"     => axiomId,
        })
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx50s::issueNx50UsingURL(url)
    def self.issueNx50UsingURL(url)
        uuid         = LucilleCore::timeStringL22()
        description  = url
        axiomId      = NxA002::make(Nx50s::axiomsFolderPath(), LucilleCore::timeStringL22(), url)
        Nx50s::commitNx50ToDatabase({
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "axiomId"     => axiomId,
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

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        type = NxAxioms::contentTypeOrNull(Nx50s::axiomsFolderPath(), item["axiomId"]) || "line"
        "[nx50] #{nx50["description"]} (#{type})"
    end

    # Nx50s::toStringForNS16(item, rt, timeReq)
    def self.toStringForNS16(item, rt, timeReq)
        type = NxAxioms::contentTypeOrNull(Nx50s::axiomsFolderPath(), item["axiomId"]) || "line"
        "[nx50] (#{"%4.2f" % rt} of #{"%4.2f" % timeReq}) #{item["description"]} (#{type})"
    end

    # Nx50s::complete(nx50)
    def self.complete(nx50)
        NxAxioms::destroy(Nx50s::axiomsFolderPath(), nx50["axiomId"]) # function accepts null ids
        Nx50s::delete(nx50["uuid"])
    end

    # Nx50s::accessContent(item)
    def self.accessContent(item)
        if item["axiomId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        NxAxioms::accessWithOptionToEdit(Nx50s::axiomsFolderPath(), item["axiomId"])
    end

    # Nx50s::accessContentsIfContents(nx50)
    def self.accessContentsIfContents(nx50)
        return if nx50["axiomId"].nil?
        NxAxioms::accessWithOptionToEdit(Nx50s::axiomsFolderPath(), nx50["axiomId"])
    end

    # --------------------------------------------------
    # nx16s

    # Nx50s::run(nx50)
    def self.run(nx50)

        uuid = nx50["uuid"]
        puts "#{Nx50s::toString(nx50)}".green
        puts "uuid: #{uuid}".yellow
        puts "axiomId: #{nx50["axiomId"]}".yellow
        puts "NxAxiom fsck: #{NxAxioms::fsck(Nx50s::axiomsFolderPath(), nx50["axiomId"])}"
        puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow
        puts ""

        puts "Starting at #{Time.new.to_s}"

        domain = Domains::interactivelyGetDomainForItemOrNull(uuid, Nx50s::toString(nx50))
        nxball = NxBalls::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7", Domains::domainBankAccountOrNull(domain)].compact)

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
                DetachedRunning::issueNew2(Nx50s::toString(nx50), Time.new.to_i, [uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])
                break
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])
                next
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx50["description"])
                if description.size > 0 then
                    Nx50s::updateDescription(nx50["uuid"], description)
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

    # Nx50s::ns16OrNull(nx50, integersEnumerator, domain)
    def self.ns16OrNull(nx50, integersEnumerator, domain)
        uuid = nx50["uuid"]
        itemDomain = Domains::getDomainForItemOrNull(uuid)
        return nil if (itemDomain and (itemDomain != domain))
        return nil if !DoNotShowUntil::isVisible(uuid)
        return nil if !InternetStatus::ns16ShouldShow(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        timeRequirementInHours = 1.5/(2 ** integersEnumerator.next()) # first value is 1.5/(2 ** 0) = 1.5 
        return nil if rt > timeRequirementInHours
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx50s::toStringForNS16(nx50, rt, timeRequirementInHours)}#{noteStr} (rt: #{rt.round(2)})".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "domain"   => Domains::getDomainForItemOrNull(uuid),
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
            "rt" => rt
        }
    end

    # Nx50s::ns16s()
    def self.ns16s()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Nx50s (Inbox)").each{|location|
            Nx50s::issueNx50UsingLocation(location)
            LucilleCore::removeFileSystemLocation(location)
        }
        integersEnumerator = LucilleCore::integerEnumerator()
        domain = Domains::getCurrentActiveDomain()
        cardinal = (domain == "eva" ? 5 : 99)
        Nx50s::nx50s()
            .reduce([]){|ns16s, nx50|
                if ns16s.size < cardinal then
                    ns16 = Nx50s::ns16OrNull(nx50, integersEnumerator, domain)
                    if ns16 then
                        ns16s << ns16
                    end
                end
                ns16s
            }
    end

    # --------------------------------------------------

    # Nx50s::nx19s()
    def self.nx19s()
        Nx50s::nx50s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx50s::toString(item),
                "lambda"   => lambda { Nx50s::run(item) }
            }
        }
    end
end
