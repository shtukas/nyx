# encoding: UTF-8

class NxOnDate # OnDate

    # NxOnDate::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxOnDates"
    end

    # NxOnDate::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{NxOnDate::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxOnDate::getNxOnDateByUUIDOrNull(uuid)
    def self.getNxOnDateByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{NxOnDate::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxOnDate::items()
    def self.items()
        LucilleCore::locationsAtFolder(NxOnDate::itemsFolderPath())
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

        coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()

        item = {
              "uuid"         => uuid,
              "unixtime"     => unixtime,
              "description"  => description,
              "date"         => date,
              "coreDataId"      => coreDataId
            }

        NxOnDate::commitItemToDisk(item)

        item
    end

    # NxOnDate::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{NxOnDate::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # -------------------------------------
    # Operations

    # NxOnDate::getItemType(item)
    def self.getItemType(item)
        type = KeyValueStore::getOrNull(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc78:#{item["uuid"]}")
        return type if type
        type1 = CoreData::contentTypeOrNull(item["coreDataId"])
        type2 = type1 || "line"
        KeyValueStore::set(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc78:#{item["uuid"]}", type2)
        type2
    end

    # NxOnDate::toString(item)
    def self.toString(item)
        "[ondt] (#{item["date"]}) #{item["description"]} (#{NxOnDate::getItemType(item)})"
    end

    # NxOnDate::accessContent(item)
    def self.accessContent(item)
        if item["coreDataId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        CoreData::accessWithOptionToEdit(item["coreDataId"])
    end

    # NxOnDate::run(item)
    def self.run(item)
        uuid = item["uuid"]

        puts "running #{NxOnDate::toString(item)}".green
        puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow
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

        puts "note:\n#{StructuredTodoTexts::getNoteOrNull(item["uuid"])}".green

        NxOnDate::accessContent(item)

        loop {

            system("clear")

            puts "running #{NxOnDate::toString(item)}".green
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(item["uuid"])}".green

            puts "access | <datecode> | note | [] | update date | exit | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            if Interpreting::match("access", command) then
                NxOnDate::accessContent(item)
                next
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                break
            end

            if Interpreting::match("note", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(item["uuid"]) || "")
                StructuredTodoTexts::setNote(item["uuid"], note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(item["uuid"])
                next
            end

            if Interpreting::match("update date", command) then
                date = NxOnDate::interactivelySelectADateOrNull()
                next if date.nil?
                item["date"] = date
                NxOnDate::commitItemToDisk(item)
                next
            end

            if Interpreting::match("exit", command) then
                return
            end

            if Interpreting::match("destroy", command) then
                NxOnDate::destroy(item)
                break
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # NxOnDate::itemToNS16(item)
    def self.itemToNS16(item)
        {
            "uuid"        => item["uuid"],
            "announce"    => NxOnDate::toString(item),
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    NxOnDate::run(item)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done '#{NxOnDate::toString(item)}' ? ", true) then
                        NxOnDate::destroy(item)
                    end
                end
            },
            "run" => lambda {
                NxOnDate::run(item)
            }
        }
    end

    # NxOnDate::ns16s()
    def self.ns16s()
        NxOnDate::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| item["date"] <= Time.new.to_s[0, 10] }
            .sort{|i1, i2| i1["date"] <=> i2["date"] }
            .map{|item| NxOnDate::itemToNS16(item) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
            .select{|ns16| DoNotShowUntil::isVisible(ns16["uuid"]) }
    end

    # NxOnDate::main()
    def self.main()
        loop {
            system("clear")

            items = NxOnDate::items()
                        .sort{|i1, i2| i1["date"] <=> i2["date"] }

            items.each_with_index{|item, indx| 
                puts "[#{indx}] #{NxOnDate::toString(item)}"
            }

            puts "<item index> | (empty) # exit".yellow
            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                item = items[indx]
                next if item.nil?
                NxOnDate::run(item)
            end

            Interpreters::mainMenuInterpreter(command)
        }
    end

    # NxOnDate::nx19s()
    def self.nx19s()
        NxOnDate::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => NxOnDate::toString(item),
                "lambda"   => lambda { NxOnDate::run(item) }
            }
        }
    end
end
