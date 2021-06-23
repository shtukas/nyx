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
        nx50["targetTimeCommitmentInHoursPerWeek"] = nil

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
        nx50["targetTimeCommitmentInHoursPerWeek"] = nil

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

        nx50["targetTimeCommitmentInHoursPerWeek"] = nil

        CoreDataTx::commit(nx50)

        nx50
    end

    # --------------------------------------------------

    # Nx50s::toStringCore(nx50)
    def self.toStringCore(nx50)
        target = nx50["targetTimeCommitmentInHoursPerWeek"]
        rt = target.to_f/7
        w = nx50["targetTimeCommitmentInHoursPerWeek"] ? " (#{target} hours/week, #{rt.round(2)})" : ""
        "[#{nx50["contentType"]}] #{nx50["description"]}#{w}"
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
            puts "stdRecoveredDailyTimeInHours: #{BankExtended::stdRecoveredDailyTimeInHours(nx50["uuid"])}".yellow
            puts "targetTimeCommitmentInHoursPerWeek: #{nx50["targetTimeCommitmentInHoursPerWeek"]}".yellow

            puts "access (partial edit) | edit description | edit contents | update time commitment | transmute | destroy | ''".yellow

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
                description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
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

            if Interpreting::match("update time commitment", command) then
                value = LucilleCore::askQuestionAnswerAsString("time commitment in hours per week (empty for abort): ")
                next if value == ""
                nx50["targetTimeCommitmentInHoursPerWeek"] = value.to_f
                CoreDataTx::commit(nx50)
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
        
        puts "running: #{Nx50s::toString(nx50)}".green

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

            puts "running: (#{"%.3f" % rt}) #{Nx50s::toString(nx50)}".green

            puts "access | landing | <datecode> | detach running | exit | completed | ''".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(nx50["uuid"], unixtime)
                break
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    ProjectItems::commit(nx50)
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

    # Nx50s::toNS16(nx50)
    def self.toNS16(nx50)
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

    # Nx50s::targetCommitmentInHoursPerWeek(nx50)
    def self.targetCommitmentInHoursPerWeek(nx50)
        nx50["targetTimeCommitmentInHoursPerWeek"] ? nx50["targetTimeCommitmentInHoursPerWeek"].to_f : 7
    end

    # Nx50s::redRecoveryTime(nx50)
    def self.redRecoveryTime(nx50)
        Nx50s::targetCommitmentInHoursPerWeek(nx50).to_f/7
    end

    # Nx50s::ns16sOrdered()
    def self.ns16sOrdered()
        # Visible, less than one hour in the past day, highest stdRecoveredDailyTime first

        items0 = CoreDataTx::getObjectsBySchema("Nx50")
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                    .map{|nx50| Nx50s::toNS16(nx50) }

        items1 = items0
                    .select{|ns16| ns16["rt"] < Nx50s::redRecoveryTime(ns16["nx50"]) }
                    
        items1a = items1
                    .select{|ns16| ns16["rt"] == 0 }
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }

        items1b = items1
                    .select{|ns16| ns16["rt"] > 0 }
                    .sort{|i1, i2| i1["rt"] <=> i2["rt"] }
                    .reverse

        items1 = items1b + items1a

        items2 = items0
                    .select{|ns16| ns16["rt"] >= Nx50s::redRecoveryTime(ns16["nx50"]) }
                    .map{|ns15|
                        ns15["announce"] = ns15["announce"].red
                        ns15
                    }
                    .sort{|i1, i2| i1["rt"] <=> i2["rt"] }

        items1.take(3) + items2 + items1.drop(3)
    end

    # Nx50s::targetForNS17()
    def self.targetForNS17()
        2
    end

    # Nx50s::ns17s()
    def self.ns17s()
        rt = BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7")
        ratio = rt.to_f/Nx50s::targetForNS17()
        [
            {
                "ratio" => ratio,
                "ns16s" => Nx50s::ns16sOrdered()
            }
        ]
    end

    # Nx50s::ns17text()
    def self.ns17text()
        rt = BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7")
        ratio = rt.to_f/Nx50s::targetForNS17()
        "(ratio: #{"%4.2f" % rt} of #{"%3.1f" % Work::targetRT()}) Nx50s"
    end
end
