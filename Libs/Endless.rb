# encoding: UTF-8

class Endless

    # Endless::toString(endless)
    def self.toString(endless)
        "[endless] #{endless["description"]}"
    end

    # Endless::toStringListing(endless)
    def self.toStringListing(endless)
        ratio = BankExtended::completionRatioRelativelyToTimeCommitmentInHoursPerWeek(endless["uuid"], endless["timeCommitmentInHoursPerWeek"])
        "[endless] (#{"%6.2f" % (ratio*100)} % of #{"%4.1f" % endless["timeCommitmentInHoursPerWeek"]}) #{endless["description"]}"
    end

    # Endless::interactivelyCreateNew()
    def self.interactivelyCreateNew()

        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        timeCommitmentInHoursPerWeek = LucilleCore::askQuestionAnswerAsString("timeCommitmentInHoursPerWeek (empty for abort): ")
        if timeCommitmentInHoursPerWeek == "" then
            return nil
        end

        timeCommitmentInHoursPerWeek = [timeCommitmentInHoursPerWeek.to_f, 0.5].max # at least 30 mins

        endless = {}
        endless["uuid"]        = uuid
        endless["schema"]      = "endless"
        endless["unixtime"]    = Time.new.to_i
        endless["description"] = description
        endless["timeCommitmentInHoursPerWeek"] = timeCommitmentInHoursPerWeek

        CoreDataTx::commit(endless)
    end

    # Endless::access(endless)
    def self.access(endless)

        uuid = endless["uuid"]

        nxball = BankExtended::makeNxBall([uuid])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = BankExtended::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Project running for more than an hour")
                end
            }
        }

        system("clear")

        puts "starting: #{Endless::toString(endless)} ( uuid: #{endless["uuid"]} )".green

        coordinates = Nx102::access(endless["contentType"], endless["payload"])
        if coordinates then
            endless["contentType"] = coordinates[0]
            endless["payload"]     = coordinates[1]
            CoreDataTx::commit(endless)
        end

        loop {

            system("clear")

            puts "running: #{Endless::toString(endless)} ( uuid: #{endless["uuid"]} ) for #{((Time.new.to_f - nxball["startUnixtime"]).to_f/3600).round(2)} hours".green

            recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
            ratio = (recoveryTime*7).to_f/endless["timeCommitmentInHoursPerWeek"]
            puts "ratio: #{ratio}"
            
            puts "timeCommitmentInHoursPerWeek: #{endless["timeCommitmentInHoursPerWeek"]}"

            puts "access | <datecode> | update description / time commitment | new item | detach running | completed | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(endless["contentType"], endless["payload"])
                if coordinates then
                    endless["contentType"] = coordinates[0]
                    endless["payload"]     = coordinates[1]
                    CoreDataTx::commit(endless)
                end
                next
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(endless["description"])
                next if description == ""
                endless["description"] = description
                CoreDataTx::commit(endless)
                next
            end

            if Interpreting::match("update time commitment", command) then
                timeCommitmentInHoursPerWeek = LucilleCore::askQuestionAnswerAsString("timeCommitmentInHoursPerWeek (empty for abort): ")
                next if timeCommitmentInHoursPerWeek == ""
                timeCommitmentInHoursPerWeek = [timeCommitmentInHoursPerWeek.to_f, 0.5].max # at least 30 mins
                endless["timeCommitmentInHoursPerWeek"] = timeCommitmentInHoursPerWeek
                CoreDataTx::commit(endless)
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Endless::toString(endless), Time.new.to_i, [uuid])
                break
            end

            if Interpreting::match("completed", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy endless ? ") then
                    CoreDataTx::delete(endless["uuid"])
                    break
                end
            end
        }

        thr.exit

        BankExtended::closeNxBall(nxball, true)
    end

    # Endless::toNS16(endless)
    def self.toNS16(endless)
        uuid = endless["uuid"]
        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        ratio = BankExtended::completionRatioRelativelyToTimeCommitmentInHoursPerWeek(endless["uuid"], endless["timeCommitmentInHoursPerWeek"])
        metric = (ratio < 1 ? ["ns:time-commitment", ratio] : ["ns:low-priority-time-commitment", ratio])
        announce = Endless::toStringListing(endless).gsub("[endless]", "[endl]")
        if ratio >= 1 then
            announce = announce.red
        end
        {
            "uuid"         => uuid,
            "metric"       => metric,
            "announce"     => announce,
            "access"       => lambda { Endless::access(endless) },
            "done"         => lambda { 
                puts "You cannot done an endless, please land on it first"
            }
        }
    end

    # Endless::ns16s()
    def self.ns16s()
        CoreDataTx::getObjectsBySchema("endless")
            .map{|endless| Endless::toNS16(endless) }
    end

    # Endless::main()
    def self.main()

        loop {
            system("clear")

            endlesss = CoreDataTx::getObjectsBySchema("endless")
                .sort{|p1, p2| BankExtended::stdRecoveredDailyTimeInHours(p1["uuid"]) <=> BankExtended::stdRecoveredDailyTimeInHours(p2["uuid"]) }

            endlesss.each_with_index{|endless, indx| 
                puts "[#{indx}] #{Endless::toStringListing(endless)}"
            }

            puts "<item index> | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                endless = endlesss[indx]
                next if endless.nil?
                Endless::access(endless)
            end
        }
    end
end
