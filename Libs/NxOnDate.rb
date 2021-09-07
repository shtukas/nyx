# encoding: UTF-8

=begin

{
    "uuid"         => String
    "unixtime"     => Float
    "description"  => String
    "catalystType" => "NxOnDate"

    "payload1" : "YYYY-MM-DD"
    "payload2" :
    "payload3" :

    "date" : payload1
}

=end

class NxOnDate # OnDate

    # NxOnDate::databaseItemToNxOnDate(item)
    def self.databaseItemToNxOnDate(item)
        item["date"]           = item["payload1"]
        item["contentType"]    = item["payload2"]
        item["contentPayload"] = item["payload3"]
        item
    end

    # NxOnDate::getNxOnDateByUUIDOrNull(uuid)
    def self.getNxOnDateByUUIDOrNull(uuid)
        item = CatalystDatabase::getItemByUUIDOrNull(uuid)
        return nil if item.nil?
        NxOnDate::databaseItemToNxOnDate(item)
    end

    # NxOnDate::nx31s()
    def self.nx31s()
        CatalystDatabase::getItemsByCatalystType("NxOnDate").map{|item|
            NxOnDate::databaseItemToNxOnDate(item)
        }
    end

    # NxOnDate::interactivelySelectADateOrNull()
    def self.interactivelySelectADateOrNull()
        datecode = LucilleCore::askQuestionAnswerAsString("date code +<weekdayname>, +<integer>day(s), +YYYY-MM-DD (empty to abort): ")
        unixtime = Utils::codeToUnixtimeOrNull(datecode)
        return nil if unixtime.nil?
        Time.at(unixtime).to_s[0, 10]
    end

    # NxOnDate::commitNxOnDateToDisk(nx31)
    def self.commitNxOnDateToDisk(nx31)
        uuid         = nx31["uuid"]
        unixtime     = nx31["unixtime"]
        description  = nx31["description"]
        catalystType = "NxOnDate"
        payload1     = nx31["date"]
        payload2     = nx31["contentType"]
        payload3     = nx31["contentPayload"]
        payload4     = nil 
        payload5     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, payload4, payload5)
    end

    # NxOnDate::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid

        unixtime     = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        catalystType = "NxOnDate"

        date = NxOnDate::interactivelySelectADateOrNull()
        return nil if date.nil?

        payload1     = date

        coordinates  = Axion::interactivelyIssueNewCoordinatesOrNull()

        payload2     = coordinates ? coordinates["contentType"] : nil
        payload3     = coordinates ? coordinates["contentPayload"] : nil
        
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        NxOnDate::getNxOnDateByUUIDOrNull(uuid)
    end

    # NxOnDate::toString(nx31)
    def self.toString(nx31)
        contentType = nx31["contentType"]
        tr1 = (contentType and contentType.size > 0) ? " (#{contentType})" : ""
        "[ondt] (#{nx31["date"]}) #{nx31["description"]}#{tr1}"
    end

    # NxOnDate::landing(nx31)
    def self.landing(nx31)

        uuid = nx31["uuid"]

        nxball = NxBalls::makeNxBall([uuid])

        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end
            }
        }

        system("clear")
        
        puts "running: #{NxOnDate::toString(nx31)} (#{BankExtended::runningTimeString(nxball)})".green
        puts "coordinates: #{nx31["contentType"]}, #{nx31["contentPayload"]}".yellow
        puts "note:\n#{StructuredTodoTexts::getNoteOrNull(nx31["uuid"])}".green

        loop {

            nx31 = NxOnDate::getNxOnDateByUUIDOrNull(nx31["uuid"])

            return if nx31.nil?

            system("clear")

            puts "running: #{NxOnDate::toString(nx31)} (#{BankExtended::runningTimeString(nxball)})".green
            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(nx31["uuid"])}".green

            puts "[item   ] access | note | [] | <datecode> | update date | detach running | done | exit".yellow
            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(nx31["uuid"], unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Axion::access(nx31["contentType"], nx31["contentPayload"], nil)
                next
            end

            if Interpreting::match("update date", command) then
                date = NxOnDate::interactivelySelectADateOrNull()
                next if date.nil?
                nx31["date"] = date
                NxOnDate::commitNxOnDateToDisk(nx31)
                next
            end

            if Interpreting::match("note", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx31["uuid"]) || "")
                StructuredTodoTexts::setNote(nx31["uuid"], note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(nx31["uuid"])
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(NxOnDate::toString(nx31), Time.new.to_i, [uuid])
                break
            end

            if Interpreting::match("done", command) then
                Axion::postAccessCleanUp(nx31["contentType"], nx31["contentPayload"])
                CatalystDatabase::delete(nx31["uuid"])
                break
            end

            Interpreters::mainMenuInterpreter(command)
        }

        thr.exit

        Axion::postAccessCleanUp(nx31["contentType"], nx31["contentPayload"])

        NxBalls::closeNxBall(nxball, true)
    end

    # NxOnDate::run(nx31)
    def self.run(nx31)
        uuid = nx31["uuid"]

        nxball = NxBalls::makeNxBall([uuid])

        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end
            }
        }

        Axion::access(nx31["contentType"], nx31["contentPayload"], nil)

        LucilleCore::pressEnterToContinue()

        if LucilleCore::askQuestionAnswerAsBoolean("done '#{NxOnDate::toString(nx31)}' ? ", true) then
            CatalystDatabase::delete(nx31["uuid"])
        end

        Axion::postAccessCleanUp(nx31["contentType"], nx31["contentPayload"])
        NxBalls::closeNxBall(nxball, true)
    end

    # NxOnDate::nx31ToNS16(nx31)
    def self.nx31ToNS16(nx31)
        {
            "uuid"        => nx31["uuid"],
            "announce"    => NxOnDate::toString(nx31),
            "commands"    => ["..", "landing", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    NxOnDate::run(nx31)
                end
                if command == "landing" then
                    NxOnDate::landing(nx31)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done '#{NxOnDate::toString(nx31)}' ? ", true) then
                        CatalystDatabase::delete(nx31["uuid"])
                    end
                end
            },
            "run" => lambda {
                NxOnDate::landing(nx31)
            }
        }
    end

    # NxOnDate::ns16s()
    def self.ns16s()
        NxOnDate::nx31s()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| item["date"] <= Time.new.to_s[0, 10] }
            .sort{|i1, i2| i1["date"] <=> i2["date"] }
            .map{|nx31| NxOnDate::nx31ToNS16(nx31) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
            .select{|ns16| DoNotShowUntil::isVisible(ns16["uuid"]) }
    end

    # NxOnDate::main()
    def self.main()
        loop {
            system("clear")

            nx31s = NxOnDate::nx31s()
                        .sort{|i1, i2| i1["date"] <=> i2["date"] }

            nx31s.each_with_index{|nx31, indx| 
                puts "[#{indx}] #{NxOnDate::toString(nx31)}"
            }

            puts "<item index> | (empty) # exit".yellow
            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                nx31 = nx31s[indx]
                next if nx31.nil?
                NxOnDate::landing(nx31)
            end

            Interpreters::mainMenuInterpreter(command)
        }
    end

    # NxOnDate::nx19s()
    def self.nx19s()
        NxOnDate::nx31s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => NxOnDate::toString(item),
                "lambda"   => lambda { NxOnDate::landing(item) }
            }
        }
    end
end
