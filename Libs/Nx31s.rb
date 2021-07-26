# encoding: UTF-8

class Nx31s # OnDate

    # Nx31s::interactivelySelectADateOrNull()
    def self.interactivelySelectADateOrNull()
        datecode = LucilleCore::askQuestionAnswerAsString("date code +<weekdayname>, +<integer>day(s), +YYYY-MM-DD (empty to abort): ")
        unixtime = Utils::codeToUnixtimeOrNull(datecode)
        return nil if unixtime.nil?
        Time.at(unixtime).to_s[0, 10]
    end

    # Nx31s::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid

        nx31 = {}
        nx31["uuid"]        = uuid
        nx31["schema"]      = "Nx31"
        nx31["unixtime"]    = Time.new.to_f

        date = Nx31s::interactivelySelectADateOrNull()
        return nil if date.nil?

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        nx31["description"] = description

        coordinates = Nx102::interactivelyIssueNewCoordinatesOrNull()
        return nil if coordinates.nil?

        nx31["contentType"] = coordinates[0]
        nx31["payload"]     = coordinates[1]

        nx31["date"]        = date

        CoreDataTx::commit(nx31)

        nx31
    end

    # Nx31s::toString(nx31)
    def self.toString(nx31)
        "[ondt] (#{nx31["date"]}) #{nx31["description"]}"
    end

    # Nx31s::access(nx31)
    def self.access(nx31)

        uuid = nx31["uuid"]

        nxball = BankExtended::makeNxBall([uuid])

        system("clear")
        
        puts "running: #{Nx31s::toString(nx31)} (#{BankExtended::runningTimeString(nxball)})".green
        puts "note:\n#{StructuredTodoTexts::getNoteOrNull(nx31["uuid"])}".green

        coordinates = Nx102::access(nx31["contentType"], nx31["payload"])
        if coordinates then
            nx31["contentType"] = coordinates[0]
            nx31["payload"]     = coordinates[1]
            CoreDataTx::commit(nx31)
        end

        loop {

            return if CoreDataTx::getObjectByIdOrNull(nx31["uuid"]).nil?

            system("clear")

            puts "running: #{Nx31s::toString(nx31)} (#{BankExtended::runningTimeString(nxball)})".green
            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(nx31["uuid"])}".green

            puts "access | note: | [] | <datecode> | update date | detach running | done | transfert | exit".yellow
            puts UIServices::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(nx31["uuid"], unixtime)
                break
            end

            if Interpreting::match("update date", command) then
                date = Nx31s::interactivelySelectADateOrNull()
                next if date.nil?
                nx31["date"] = date
                CoreDataTx::commit(nx31)
                next
            end

            if Interpreting::match("note:", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx31["uuid"]) || "")
                StructuredTodoTexts::setNote(nx31["uuid"], note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(nx31["uuid"])
                next
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(nx31["contentType"], nx31["payload"])
                if coordinates then
                    nx31["contentType"] = coordinates[0]
                    nx31["payload"]     = coordinates[1]
                    CoreDataTx::commit(nx31)
                end
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx31s::toString(nx31), Time.new.to_i, [uuid])
                break
            end

            if Interpreting::match("done", command) then
                Nx102::postAccessCleanUp(nx31["contentType"], nx31["payload"])
                CoreDataTx::delete(nx31["uuid"])
                break
            end

            if Interpreting::match("transfert", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Recasting '#{Nx31s::toString(nx31)}' as Nx50", true) then
                    Nx50s::transmuteToNx50UsingNx31Interactive(nx31)
                end
                break
            end

            UIServices::mainMenuInterpreter(command)
        }
    end

    # Nx31s::nx31ToNS16(nx31)
    def self.nx31ToNS16(nx31)
        {
            "uuid"     => nx31["uuid"],
            "announce" => Nx31s::toString(nx31),
            "access"   => lambda { Nx31s::access(nx31) },
            "done"     => lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx31s::toString(nx31)}' ? ", true) then
                    CoreDataTx::delete(nx31["uuid"])
                end
            },
            "metric"     => 0.1 + MetricUtils::dateToMetricShiftIncreasing(nx31["date"]),
            "domainuuid" => nil
        }
    end

    # Nx31s::ns16s()
    def self.ns16s()
        CoreDataTx::getObjectsBySchema("Nx31")
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| item["date"] <= Time.new.to_s[0, 10] }
            .sort{|i1, i2| i1["date"] <=> i2["date"] }
            .map{|nx31| Nx31s::nx31ToNS16(nx31) }
    end

    # Nx31s::main()
    def self.main()
        loop {
            system("clear")

            nx31s = CoreDataTx::getObjectsBySchema("Nx31")
                .sort{|i1, i2| i1["date"] <=> i2["date"] }

            nx31s.each_with_index{|nx31, indx| 
                puts "[#{indx}] #{Nx31s::toString(nx31)}"
            }

            puts "<item index> | (empty) # exit".yellow
            puts UIServices::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                nx31 = nx31s[indx]
                next if nx31.nil?
                Nx31s::access(nx31)
            end

            UIServices::mainMenuInterpreter(command)
        }
    end

    # Nx31s::nx19s()
    def self.nx19s()
        CoreDataTx::getObjectsBySchema("Nx31").map{|item|
            {
                "announce" => Nx31s::toString(item),
                "lambda"   => lambda { Nx31s::access(item) }
            }
        }
    end
end
