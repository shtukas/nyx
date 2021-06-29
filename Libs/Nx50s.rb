# encoding: UTF-8

class Nx50s

    # Nx50s::importURLAsNewURLNx50(url)
    def self.importURLAsNewURLNx50(url)
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

    # Nx50s::importLocationAsNewAionPointNx50(location)
    def self.importLocationAsNewAionPointNx50(location)
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

    # Nx50s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        uuid = nx50["uuid"]

        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

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
            "rt"       => rt,
            "unixtime" => nx50["unixtime"],
            "nx50"     => nx50
        }
    end

    # Nx50s::getVisibleBelowRedRTNS16ByUUIDOrNull(uuid)
    def self.getVisibleBelowRedRTNS16ByUUIDOrNull(uuid)
        nx50 = CoreDataTx::getObjectByIdOrNull(uuid)
        return nil if nx50.nil?
        return nil if !DoNotShowUntil::isVisible(nx50["uuid"])
        ns16 = Nx50s::ns16OrNull(nx50)
        return nil if ns16.nil?
        return nil if (ns16["rt"] >= 1)
        ns16
    end

    # Nx50s::ns16sVisibleBelowRedRTOrdered()
    def self.ns16sVisibleBelowRedRTOrdered()
        CoreDataTx::getObjectsBySchema("Nx50")
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .map{|nx50| Nx50s::ns16OrNull(nx50) }
            .compact
    end

    # Nx50s::firstTriplet(index)
    def self.firstTriplet(index)
        items = Nx50s::ns16sVisibleBelowRedRTOrdered().drop(3*index).take(3)
        if items.map{|ns16| ns16["rt"] }.inject(0, :+) > 2.to_f/(index+1) then
            return Nx50s::firstTriplet(index+1)
        end
        items.sort{|i1, i2| i1["rt"] <=> i2["rt"] }
    end

    # Nx50s::todayTimeCompletionRatio()
    def self.todayTimeCompletionRatio()
        Bank::valueAtDate("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7", Utils::today()).to_f/(3*3600)
    end

    # Nx50s::ns17s()
    def self.ns17s()
        [
            {
                "ratio" => Nx50s::todayTimeCompletionRatio(),
                "ns16s" => Nx50s::firstTriplet(0)
            }
        ]
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
