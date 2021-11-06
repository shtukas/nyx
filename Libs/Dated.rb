# encoding: UTF-8

class Dated # OnDate

    # Dated::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Items/Dateds"
    end

    # Dated::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Dated::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Dated::getDatedByUUIDOrNull(uuid)
    def self.getDatedByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{Dated::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Dated::items()
    def self.items()
        LucilleCore::locationsAtFolder(Dated::itemsFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|x1, x2|  x1["date"] <=> x2["date"]}
    end

    # Dated::interactivelySelectADateOrNull()
    def self.interactivelySelectADateOrNull()
        datecode = LucilleCore::askQuestionAnswerAsString("date code +<weekdayname>, +<integer>day(s), +YYYY-MM-DD (empty to abort): ")
        unixtime = Utils::codeToUnixtimeOrNull(datecode)
        return nil if unixtime.nil?
        Time.at(unixtime).to_s[0, 10]
    end

    # Dated::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = LucilleCore::timeStringL22()

        unixtime = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        date = Dated::interactivelySelectADateOrNull()
        return nil if date.nil?

        coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()

        item = {
              "uuid"        => uuid,
              "unixtime"    => unixtime,
              "description" => description,
              "date"        => date,
              "coreDataId"  => coreDataId
            }

        Dated::commitItemToDisk(item)

        item
    end

    # Dated::issueItemUsingText(text, unixtime, date)
    def self.issueItemUsingText(text, unixtime, date)
        uuid        = LucilleCore::timeStringL22()
        description = text.strip.lines.first.strip || "todo text @ #{Time.new.to_s}" 
        coreDataId  = CoreData::issueTextDataObjectUsingText(text)
        Dated::commitItemToDisk({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "date"        => date,
            "coreDataId"  => coreDataId
        })
        Dated::getDatedByUUIDOrNull(uuid)
    end

    # Dated::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Dated::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # -------------------------------------
    # Operations

    # Dated::getItemType(item)
    def self.getItemType(item)
        type = KeyValueStore::getOrNull(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc78:#{item["uuid"]}")
        return type if type
        type1 = CoreData::contentTypeOrNull(item["coreDataId"])
        type2 = type1 || "line"
        KeyValueStore::set(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc78:#{item["uuid"]}", type2)
        type2
    end

    # Dated::toString(item)
    def self.toString(item)
        "[date] (#{item["date"]}) #{item["description"]} (#{Dated::getItemType(item)})"
    end

    # Dated::accessContent(item)
    def self.accessContent(item)
        if item["coreDataId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        CoreData::accessWithOptionToEdit(item["coreDataId"])
    end

    # Dated::run(item)
    def self.run(item)

        system("clear")

        uuid = item["uuid"]

        puts "running #{Dated::toString(item)}".green
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

        Dated::accessContent(item)

        loop {

            system("clear")

            puts "running #{Dated::toString(item)}".green
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(item["uuid"])}".green

            puts "access | <datecode> | note | [] | update description | update date | update contents | exit | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            if Interpreting::match("access", command) then
                Dated::accessContent(item)
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

            if Interpreting::match("update description", command) then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                item["description"] = description
                Dated::commitItemToDisk(item)
                next
            end

            if Interpreting::match("update date", command) then
                date = Dated::interactivelySelectADateOrNull()
                next if date.nil?
                item["date"] = date
                Dated::commitItemToDisk(item)
                next
            end

            if Interpreting::match("update contents", command) then
                coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()
                return if coreDataId.nil?
                item["coreDataId"] = coreDataId
                Dated::commitItemToDisk(item)
                next
            end

            if Interpreting::match("exit", command) then
                return
            end

            if Interpreting::match("destroy", command) then
                Dated::destroy(item)
                break
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Dated::itemToNS16(item)
    def self.itemToNS16(item)
        {
            "uuid"        => item["uuid"],
            "announce"    => Dated::toString(item),
            "commands"    => ["..", "redate", ">hud", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Dated::run(item)
                end
                if command == "redate" then
                    date = Dated::interactivelySelectADateOrNull()
                    return if date.nil?
                    item["date"] = date
                    puts JSON.pretty_generate(item)
                    Dated::commitItemToDisk(item)
                end
                if command == ">hud" then
                    Hud::issueNewFromDescriptionAndCoreDataId(Dated::toString(item), item["coreDataId"])
                    Dated::destroy(item)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done '#{Dated::toString(item)}' ? ", true) then
                        Dated::destroy(item)
                    end
                end
            },
            "run" => lambda {
                Dated::run(item)
            }
        }
    end

    # Dated::ns16s()
    def self.ns16s()
        Dated::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| item["date"] <= Time.new.to_s[0, 10] }
            .sort{|i1, i2| i1["date"] <=> i2["date"] }
            .map{|item| Dated::itemToNS16(item) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # Dated::main()
    def self.main()
        loop {
            system("clear")

            items = Dated::items()
                        .sort{|i1, i2| i1["date"] <=> i2["date"] }

            items.each_with_index{|item, indx| 
                puts "[#{indx}] #{Dated::toString(item)}"
            }

            puts "<item index> | (empty) # exit".yellow
            puts Interpreters::makersAndDiversCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                item = items[indx]
                next if item.nil?
                Dated::run(item)
            end

            Interpreters::makersAndDiversInterpreter(command)
        }
    end

    # Dated::nx19s()
    def self.nx19s()
        Dated::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Dated::toString(item),
                "lambda"   => lambda { Dated::run(item) }
            }
        }
    end
end
