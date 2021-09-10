# encoding: UTF-8

class NxOnDate # OnDate

    # NxOnDate::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxOnDates"
    end

    # NxOnDate::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{NxOnDate::repositoryFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxOnDate::axiomsRepositoryFolderPath()
    def self.axiomsRepositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxOnDates-axioms"
    end

    # NxOnDate::getNxOnDateByUUIDOrNull(uuid)
    def self.getNxOnDateByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{NxOnDate::repositoryFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxOnDate::nx31s()
    def self.nx31s()
        LucilleCore::locationsAtFolder(NxOnDate::repositoryFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|x1, x2|  x1["date"] <=> x2["date"]}
    end

    # NxOnDate::interactivelySelectADateOrNull()
    def self.interactivelySelectADateOrNull()
        datecode = LucilleCore::askQuestionAnswerAsString("date code +<weekdayname>, +<integer>day(s), +YYYY-MM-DD (empty to abort): ")
        unixtime = Utils::codeToUnixtimeOrNull(datecode)
        return nil if unixtime.nil?
        Time.at(unixtime).to_s[0, 10]
    end

    # NxOnDate::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = LucilleCore::timeStringL22()

        unixtime     = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        date = NxOnDate::interactivelySelectADateOrNull()
        return nil if date.nil?

        axiomId = NxAxioms::interactivelyCreateNewAxiom_EchoIdOrNull(NxOnDate::axiomsRepositoryFolderPath(), LucilleCore::timeStringL22())

        item = {
              "uuid"         => uuid,
              "unixtime"     => unixtime,
              "description"  => description,
              "date"         => date,
              "axiomId"      => axiomId
            }

        NxOnDate::commitItemToDisk(item)

        item

    end

    # NxOnDate::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{NxOnDate::repositoryFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # -------------------------------------
    # Operations

    # NxOnDate::toString(item)
    def self.toString(item)
        "[ondt] (#{item["date"]}) #{item["description"]}"
    end

    # NxOnDate::accessContent(item)
    def self.accessContent(item)
        if item["axiomId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        NxAxioms::accessWithOptionToEdit(NxOnDate::axiomsRepositoryFolderPath(), item["axiomId"])
    end

    # NxOnDate::accessContentsIfContents(item)
    def self.accessContentsIfContents(item)
        return if item["axiomId"].nil?
        NxAxioms::accessWithOptionToEdit(NxOnDate::axiomsRepositoryFolderPath(), item["axiomId"])
    end

    # NxOnDate::landing(nx31)
    def self.landing(nx31)

        uuid = nx31["uuid"]

        system("clear")
        
        puts "running: #{NxOnDate::toString(nx31)} (#{BankExtended::runningTimeString(nxball)})".green
        puts "axiomId: #{nx31["axiomId"]}".yellow
        puts "note:\n#{StructuredTodoTexts::getNoteOrNull(nx31["uuid"])}".green

        loop {

            nx31 = NxOnDate::getNxOnDateByUUIDOrNull(nx31["uuid"])

            return if nx31.nil?

            system("clear")

            puts "running: #{NxOnDate::toString(nx31)} (#{BankExtended::runningTimeString(nxball)})".green
            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(nx31["uuid"])}".green

            puts "[item   ] access | <datecode> | note | [] | update date | exit | destroy".yellow
            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if Interpreting::match("access", command) then
                NxOnDate::accessContent(nx31)
                next
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(nx31["uuid"], unixtime)
                break
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

            if Interpreting::match("update date", command) then
                date = NxOnDate::interactivelySelectADateOrNull()
                next if date.nil?
                nx31["date"] = date
                NxOnDate::commitItemToDisk(nx31)
                next
            end

            if Interpreting::match("destroy", command) then
                NxAxioms::destroy(NxOnDate::axiomsRepositoryFolderPath(), nx31["axiomId"])
                NxOnDate::destroy(nx31)
                break
            end

            Interpreters::mainMenuInterpreter(command)
        }
    end

    # NxOnDate::run(nx31)
    def self.run(nx31)
        uuid = nx31["uuid"]

        puts "running #{NxOnDate::toString(nx31)}".green
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid])

        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end
            }
        }

        NxOnDate::accessContentsIfContents(item)

        if LucilleCore::askQuestionAnswerAsBoolean("done '#{NxOnDate::toString(nx31)}' ? ") then
            NxOnDate::destroy(nx31)
        end

        thr.exit

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
                        NxOnDate::destroy(nx31)
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
