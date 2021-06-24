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

    # NxFloat::selectOneFloatOrNull()
    def self.selectOneFloatOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("float", CoreDataTx::getObjectsBySchema("NxFloat"), lambda { |float| NxFloat::toString(float) })
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

            puts "access | edit description | edit contents | transmute | detach running | exit | completed | ''".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(float["contentType"], float["payload"])
                if coordinates then
                    float["contentType"] = coordinates[0]
                    float["payload"]     = coordinates[1]
                    CoreDataTx::commit(float)
                end
                next
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

    # NxFloat::main()
    def self.main()
        loop {
            system('clear')
            puts "NxFloat (main)"
            options = [
                "new float",
                "floats dive"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "new float" then
                new float
            end
            if option == "floats dive" then
                loop {
                    system("clear")
                    float = NxFloat::selectOneFloatOrNull()
                    return if float.nil?
                    NxFloat::access(float)
                }
            end
        }
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
