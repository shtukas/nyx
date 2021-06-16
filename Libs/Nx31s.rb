# encoding: UTF-8

class Nx31s

    # Nx31s::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid

        nx31 = {}
        nx31["uuid"]        = uuid
        nx31["schema"]      = "Nx31"
        nx31["unixtime"]    = Time.new.to_f

        datecode = LucilleCore::askQuestionAnswerAsString("date code +<weekdayname>, +<integer>day(s), +YYYY-MM-DD (empty to abort): ")
        unixtime = Utils::codeToUnixtimeOrNull(datecode)
        return nil if unixtime.nil?
        date = Time.at(unixtime).to_s[0, 10]

        coordinates = Nx102::interactivelyIssueNewCoordinates3OrNull()
        return nil if coordinates.nil?

        nx31["description"] = coordinates[0]
        nx31["contentType"] = coordinates[1]
        nx31["payload"]     = coordinates[2]

        nx31["date"]        = date

        CoreDataTx::commit(nx31)

        nx31
    end

    # Nx31s::toString(nx31)
    def self.toString(nx31)
        "[ondt] (#{nx31["date"]}) #{nx31["description"]}"
    end

    # Nx31s::runNx31(nx31)
    def self.runNx31(nx31)

        uuid = nx31["uuid"]

        system("clear")
        
        puts "running: #{Nx31s::toString(nx31)}".green

        coordinates = Nx102::access(nx31["contentType"], nx31["payload"])
        if coordinates then
            nx31["contentType"] = coordinates[0]
            nx31["payload"]     = coordinates[1]
            CoreDataTx::commit(nx31)
        end

        loop {

            return if CoreDataTx::getObjectByIdOrNull(nx31["uuid"]).nil?

            system("clear")

            puts "running: #{Nx31s::toString(nx31)}".green

            puts "access | <datecode> | detach running | done | (empty) # default # exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(nx31["uuid"], unixtime)
                break
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(nx31["contentType"], nx31["payload"])
                if coordinates then
                    nx31["contentType"] = coordinates[0]
                    nx31["payload"]     = coordinates[1]
                    ProjectItems::commit(nx31)
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
        }
    end

    # Nx31s::nx31ToNS16(nx31)
    def self.nx31ToNS16(nx31)
        {
            "uuid"     => nx31["uuid"],
            "announce" => Nx31s::toString(nx31),
            "access"   => lambda{ Nx31s::runNx31(nx31) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx31s::toString(nx31)}' ? ", true) then
                    CoreDataTx::delete(nx31["uuid"])
                end
            }
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

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                nx31 = nx31s[indx]
                next if nx31.nil?
                Nx31s::runNx31(nx31)
            end
        }
    end
end