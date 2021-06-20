# encoding: UTF-8

class Endless

    # Endless::toString(endless)
    def self.toString(endless)
        "[endless] #{endless["description"]}"
    end

    # Endless::toStringListing(endless)
    def self.toStringListing(endless)
        rt = BankExtended::stdRecoveredDailyTimeInHours(endless["uuid"])
        targetRT = endless["targetRT"]
        "[endless] (rt: #{"%4.2f" % rt} of #{"%3.1f" % targetRT}) #{endless["description"]}"
    end

    # Endless::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()

        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        targetRT = LucilleCore::askQuestionAnswerAsString("targetRT (empty for abort): ")
        if targetRT == "" then
            return nil
        end

        targetRT = [targetRT.to_f, 0.5].max # at least 30 mins

        endless = {}
        endless["uuid"]        = uuid
        endless["schema"]      = "endless"
        endless["unixtime"]    = Time.new.to_i
        endless["description"] = description
        endless["targetRT"]    = targetRT

        CoreDataTx::commit(endless)
        endless
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
                    Utils::onScreenNotification("Catalyst", "Endless running for more than an hour")
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
            ratio = (recoveryTime*7).to_f/endless["targetRT"]
            puts "ratio: #{ratio}"
            
            puts "targetRT: #{endless["targetRT"]}"

            puts "access | <datecode> | update description / update target rt | new item | detach running | exit | completed".yellow

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

            if Interpreting::match("update target rt", command) then
                targetRT = LucilleCore::askQuestionAnswerAsString("targetRT (empty for abort): ")
                next if targetRT == ""
                targetRT = [targetRT.to_f, 0.5].max # at least 30 mins
                endless["targetRT"] = targetRT
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
        announce = Endless::toStringListing(endless).gsub("[endless]", "[endl]")
        ratio = BankExtended::stdRecoveredDailyTimeInHours(endless["uuid"]).to_f/endless["targetRT"]
        {
            "uuid"         => uuid,
            "announce"     => announce,
            "access"       => lambda { Endless::access(endless) },
            "done"         => lambda { 
                puts "You cannot done an endless, please land on it first"
                LucilleCore::pressEnterToContinue()
            },
            "x-ratio"      => ratio
        }
    end

    # Endless::ns16sOrdered()
    def self.ns16sOrdered()
        CoreDataTx::getObjectsBySchema("endless")
            .map{|endless| Endless::toNS16(endless) }
            .select{|ns16| ns16["x-ratio"] < 1 }
            .sort{|i1, i2| i1["x-ratio"] <=> i2["x-ratio"] }
    end

    # Endless::ns17s()
    def self.ns17s()
        Endless::ns16sOrdered()
            .map{|item| 
                {
                    "ratio" => item["x-ratio"],
                    "ns16s" => [item]
                }
            }
    end

    # Endless::ns17sTexts()
    def self.ns17sTexts()
        Endless::ns16sOrdered()
            .map{|item| 
                ratio = item["x-ratio"].to_f/1
                "(ratio: #{"%4.2f" % ratio} of #{"%3.1f" % 1}) #{item["announce"]}"
            }
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
