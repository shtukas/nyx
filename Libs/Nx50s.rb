# encoding: UTF-8

class Nx50s

    # Nx50s::interactivelyDetermineNewItemUnixtimeOrNull()
    def self.interactivelyDetermineNewItemUnixtimeOrNull()
        system('clear')
        puts "Select the belore item:"
        items = CoreDataTx::getObjectsBySchema("Nx50")
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Nx50s::toString(item) })
        return nil if item.nil?
        loop {
            return nil if items.size < 2
            if items[0]["uuid"] == item["uuid"] then
                return (items[0]["unixtime"]+items[1]["unixtime"]).to_f/2
            end
            items.shift
            next
        }
    end

    # Nx50s::urlToNx50(url)
    def self.urlToNx50(url)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = url
        nx50["contentType"] = "Url"
        nx50["payload"]     = url

        CoreDataTx::commit(nx50)
        nil
    end

    # Nx50s::locationToNx50(location)
    def self.locationToNx50(location)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = File.basename(location) 
        nx50["contentType"] = "AionPoint"
        nx50["payload"]     = AionCore::commitLocationReturnHash(El1zabeth.new(), location)

        CoreDataTx::commit(nx50)
        nil
    end

    # Nx50s::textToNx50Interactive(text)
    def self.textToNx50Interactive(text)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = text.lines.first.strip
        nx50["contentType"] = "Text"
        nx50["payload"]     = BinaryBlobsService::putBlob(text)

        nx50["unixtime"]    = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)

        CoreDataTx::commit(nx50)
        nil
    end

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        nx50["description"] = description

        coordinates = Nx102::interactivelyIssueNewCoordinatesOrNull()
        return nil if coordinates.nil?

        nx50["contentType"] = coordinates[0]
        nx50["payload"]     = coordinates[1]

        nx50["unixtime"]    = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)

        CoreDataTx::commit(nx50)

        nx50
    end

    # --------------------------------------------------

    # Nx50s::toStringCore(nx50)
    def self.toStringCore(nx50)
        "[#{nx50["contentType"]}] #{nx50["description"]}"
    end

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        "[nx50] #{Nx50s::toStringCore(nx50)}"
    end

    # Nx50s::complete(nx50)
    def self.complete(nx50)
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s-Completion-Log.txt", "a"){|f| f.puts("#{Time.new.to_s}|#{Time.new.to_i}|#{Nx50s::toString(nx50)}") }
        Nx102::postAccessCleanUp(nx50["contentType"], nx50["payload"])
        CoreDataTx::delete(nx50["uuid"])
    end

    # Nx50s::access(nx50)
    def self.access(nx50)

        uuid = nx50["uuid"]

        nxball = BankExtended::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = BankExtended::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx50 item running for more than an hour")
                end
            }
        }

        system("clear")
        
        puts "running: #{Nx50s::toString(nx50)} (#{BankExtended::runningTimeString(nxball)})".green
        puts "note: #{KeyValueStore::getOrNull(nil, "b8b66f79-d776-425c-a00c-d0d1e60d865a:#{nx50["uuid"]}")}".yellow

        coordinates = Nx102::access(nx50["contentType"], nx50["payload"])
        if coordinates then
            nx50["contentType"] = coordinates[0]
            nx50["payload"]     = coordinates[1]
            CoreDataTx::commit(nx50)
        end

        loop {

            return if CoreDataTx::getObjectByIdOrNull(nx50["uuid"]).nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: (#{"%.3f" % rt}) #{Nx50s::toString(nx50)} (#{BankExtended::runningTimeString(nxball)})".green
            puts "note: #{KeyValueStore::getOrNull(nil, "b8b66f79-d776-425c-a00c-d0d1e60d865a:#{nx50["uuid"]}")}".yellow

            puts "access | note: | landing | <datecode> | detach running | exit | completed | ''".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(nx50["uuid"], unixtime)
                break
            end

            if Interpreting::match("note:", command) then
                note = LucilleCore::askQuestionAnswerAsString("note: ")
                KeyValueStore::set(nil, "b8b66f79-d776-425c-a00c-d0d1e60d865a:#{nx50["uuid"]}", note)
                next
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    CoreDataTx::commit(nx50)
                end
                next
            end

            if Interpreting::match("landing", command) then
                Nx50s::landing(nx50)
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx50s::toString(nx50), Time.new.to_i, [uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])
                break
            end

            if Interpreting::match("completed", command) then
                Nx50s::complete(nx50)
                break
            end

            if Interpreting::match("''", command) then
                UIServices::operationalInterface()
            end
        }

        thr.exit

        BankExtended::closeNxBall(nxball, true)

        Nx102::postAccessCleanUp(nx50["contentType"], nx50["payload"])
    end

    # Nx50s::landing(nx50)
    def self.landing(nx50)
        loop {

            system("clear")

            puts Nx50s::toString(nx50)

            puts "uuid: #{nx50["uuid"]}".yellow
            puts "coordinates: #{nx50["contentType"]}, #{nx50["payload"]}".yellow

            unixtime = DoNotShowUntil::getUnixtimeOrNull(nx50["uuid"])
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(nx50["uuid"])}".yellow

            puts "access (partial edit) | edit description | edit contents | transmute | destroy | ''".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    CoreDataTx::commit(nx50)
                end
            end

            if Interpreting::match("edit description", command) then
                description = Utils::editTextSynchronously(nx50["description"])
                if description.size > 0 then
                    nx50["description"] = description
                    CoreDataTx::commit(nx50)
                end
            end

            if Interpreting::match("edit contents", command) then
                coordinates = Nx102::edit(nx50["description"], nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    CoreDataTx::commit(nx50)
                end
            end

            if Interpreting::match("transmute", command) then
                coordinates = Nx102::transmute(nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    CoreDataTx::commit(nx50)
                end
            end

            if Interpreting::match("destroy", command) then
                Nx50s::complete(nx50)
                break
            end

            if Interpreting::match("''", command) then
                UIServices::operationalInterface()
            end
        }
    end

    # Nx50s::maintenance()
    def self.maintenance()
        if CoreDataTx::getObjectsBySchema("Nx50").size <= 30 then
            CoreDataTx::getObjectsBySchema("quark")
                .sample(20)
                .each{|object|
                    object["schema"] = "Nx50"
                    CoreDataTx::commit(object)
                }
        end
    end

    # Nx50s::getCompletionLogUnixtimes()
    def self.getCompletionLogUnixtimes()
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s-Completion-Log.txt"
        IO.read(filepath)
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0}
            .map{|line| line.split("|")[1].to_i }
    end

    # Nx50s::completionLogSize(days)
    def self.completionLogSize(days)
        horizon = Time.new.to_i - days*86400
        Nx50s::getCompletionLogUnixtimes().select{|unixtime| unixtime >= horizon }.size
    end

    # --------------------------------------------------

    # Nx50s::saturation(nx50)
    def self.saturation(nx50)
        # This function returns the recovery time after with the item is saturated
        t1 = Bank::valueOverTimespan(nx50["uuid"], 86400*14)
        tx = t1.to_f/(7*3600) # multiple of 7 hours over two weeks
        Math.exp(-tx)
    end

    # Nx50s::ns16(nx50)
    def self.ns16(nx50)
        uuid = nx50["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        saturation = Nx50s::saturation(nx50)
        announce = "[nx50] (#{"%4.2f" % rt}) #{Nx50s::toStringCore(nx50)}".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "access"   => lambda{ Nx50s::access(nx50) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx50s::toString(nx50)}' ? ", true) then
                    Nx50s::complete(nx50)
                end
            },
            "unixtime"   => nx50["unixtime"],
            "nx50"       => nx50,
            "rt"         => rt,
            "saturation" => saturation,
            "isVisible"  => DoNotShowUntil::isVisible(uuid)
        }
    end

    # Nx50s::operationalNS16OrNull(nx50)
    def self.operationalNS16OrNull(nx50)
        ns16 = Nx50s::ns16(nx50)
        return nil if !ns16["isVisible"]
        return nil if ns16["rt"] >= ns16["saturation"]
        ns16
    end

    # Nx50s::getOperationalNS16ByUUIDOrNull(uuid)
    def self.getOperationalNS16ByUUIDOrNull(uuid)
        nx50 = CoreDataTx::getObjectByIdOrNull(uuid)
        return nil if nx50.nil?
        Nx50s::operationalNS16OrNull(nx50)
    end

    # Nx50s::orderedOperationalNS16s()
    def self.orderedOperationalNS16s()
        CoreDataTx::getObjectsBySchema("Nx50")
            .map{|nx50| Nx50s::operationalNS16OrNull(nx50) }
            .compact
    end

    # Nx50s::firstTriplet(index)
    def self.firstTriplet(index)
        groupIsSaturated = lambda {|items, saturationRatio|
            rt = items.map{|item| item["rt"] }.inject(0, :+)
            saturation = items.map{|item| item["saturation"] }.inject(0, :+)
            rt >= saturationRatio * saturation
        }
        items = Nx50s::orderedOperationalNS16s().drop(3*index).take(3)
        if groupIsSaturated.call(items, 2.to_f/(index+1)) then
            return Nx50s::firstTriplet(index+1)
        end
        items.sort{|i1, i2| i1["rt"] <=> i2["rt"] }
    end

    # Nx50s::ns16s()
    def self.ns16s()
        is1 = Nx50s::firstTriplet(0)

        is2 = []
        is1 + is2
    end

    # Nx50s::nx19s()
    def self.nx19s()
        CoreDataTx::getObjectsBySchema("Nx50").map{|item|
            {
                "announce" => Nx50s::toString(item),
                "lambda"   => lambda { Nx50s::access(item) }
            }
        }
    end
end
