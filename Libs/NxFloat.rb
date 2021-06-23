# encoding: UTF-8

class NxFloat

    # NxFloat::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid

        float = {}
        float["uuid"]        = uuid
        float["schema"]      = "NxFloat"
        float["unixtime"]    = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        float["description"] = description

        coordinates = Nx102::interactivelyIssueNewCoordinatesOrNull()
        return nil if coordinates.nil?

        float["contentType"] = coordinates[0]
        float["payload"]     = coordinates[1]

        CoreDataTx::commit(float)

        float
    end

    # --------------------------------------------------

    # NxFloat::toString(float)
    def self.toString(float)
        "[float] [#{float["contentType"]}] #{float["description"]}"
    end

    # NxFloat::complete(float)
    def self.complete(float)
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s-Completion-Log.txt", "a"){|f| f.puts("#{Time.new.to_s}|#{Time.new.to_i}|#{NxFloat::toString(float)}") }
        Nx102::postAccessCleanUp(float["contentType"], float["payload"])
        CoreDataTx::delete(float["uuid"])
    end

    # NxFloat::landing(float)
    def self.landing(float)
        loop {

            system("clear")

            puts NxFloat::toString(float)

            puts "uuid: #{float["uuid"]}".yellow
            puts "coordinates: #{float["contentType"]}, #{float["payload"]}".yellow

            unixtime = DoNotShowUntil::getUnixtimeOrNull(float["uuid"])
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end

            puts "access (partial edit) | edit description | edit contents | transmute | destroy | ''".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(float["contentType"], float["payload"])
                if coordinates then
                    float["contentType"] = coordinates[0]
                    float["payload"]     = coordinates[1]
                    CoreDataTx::commit(float)
                end
            end

            if Interpreting::match("edit description", command) then
                description = Utils::editTextSynchronously(float["description"])
                if description.size > 0 then
                    float["description"] = description
                    CoreDataTx::commit(float)
                end
            end

            if Interpreting::match("edit contents", command) then
                coordinates = Nx102::edit(float["description"], float["contentType"], float["payload"])
                if coordinates then
                    float["contentType"] = coordinates[0]
                    float["payload"]     = coordinates[1]
                    CoreDataTx::commit(float)
                end
            end

            if Interpreting::match("transmute", command) then
                coordinates = Nx102::transmute(float["contentType"], float["payload"])
                if coordinates then
                    float["contentType"] = coordinates[0]
                    float["payload"]     = coordinates[1]
                    CoreDataTx::commit(float)
                end
            end

            if Interpreting::match("destroy", command) then
                NxFloat::complete(float)
                break
            end

            if Interpreting::match("''", command) then
                UIServices::operationalInterface()
                return "ns:loop"
            end
        }
    end

    # NxFloat::maintenance()
    def self.maintenance()
        if CoreDataTx::getObjectsBySchema("NxFloat").size <= 30 then
            CoreDataTx::getObjectsBySchema("quark")
                .sample(20)
                .each{|object|
                    object["schema"] = "NxFloat"
                    CoreDataTx::commit(object)
                }
        end
    end

    # NxFloat::getCompletionLogUnixtimes()
    def self.getCompletionLogUnixtimes()
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nx50s-Completion-Log.txt"
        IO.read(filepath)
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0}
            .map{|line| line.split("|")[1].to_i }
    end

    # NxFloat::completionLogSize(days)
    def self.completionLogSize(days)
        horizon = Time.new.to_i - days*86400
        NxFloat::getCompletionLogUnixtimes().select{|unixtime| unixtime >= horizon }.size
    end

    # --------------------------------------------------

    # NxFloat::access(float)
    def self.access(float)

        uuid = float["uuid"]

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
        
        puts "running: #{NxFloat::toString(float)}".green

        coordinates = Nx102::access(float["contentType"], float["payload"])
        if coordinates then
            float["contentType"] = coordinates[0]
            float["payload"]     = coordinates[1]
            CoreDataTx::commit(float)
        end

        loop {

            return if CoreDataTx::getObjectByIdOrNull(float["uuid"]).nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: (#{"%.3f" % rt}) #{NxFloat::toString(float)}".green

            puts "access | landing | <datecode> | detach running | exit | completed | ''".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(float["uuid"], unixtime)
                break
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(float["contentType"], float["payload"])
                if coordinates then
                    float["contentType"] = coordinates[0]
                    float["payload"]     = coordinates[1]
                    CoreDataTx::commit(float)
                end
                next
            end

            if Interpreting::match("landing", command) then
                NxFloat::landing(float)
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(NxFloat::toString(float), Time.new.to_i, [uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])
                break
            end

            if Interpreting::match("completed", command) then
                NxFloat::complete(float)
                break
            end

            if Interpreting::match("''", command) then
                UIServices::operationalInterface()
            end
        }

        thr.exit

        BankExtended::closeNxBall(nxball, true)

        Nx102::postAccessCleanUp(float["contentType"], float["payload"])
    end

    # NxFloat::toNS16(float)
    def self.toNS16(float)
        uuid = float["uuid"]

        {
            "uuid"     => uuid,
            "announce" => "[floa] [#{float["contentType"]}] #{float["description"]}",
            "access"   => lambda{ NxFloat::access(float) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{NxFloat::toString(float)}' ? ", true) then
                    NxFloat::complete(float)
                end
            }
        }
    end

    # NxFloat::ns16s()
    def self.ns16s()
        CoreDataTx::getObjectsBySchema("NxFloat")
                .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                .map{|float| NxFloat::toNS16(float) }
    end

    # NxFloat::nx19s()
    def self.nx19s()
        CoreDataTx::getObjectsBySchema("NxFloat").map{|item|
            {
                "announce" => NxFloat::toString(item),
                "lambda"   => lambda { NxFloat::access(item) }
            }
        }
    end
end
