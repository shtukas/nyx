# encoding: UTF-8

class Nx08s # OnDate

    # Nx08s::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/Nx08s"
    end

    # Nx08s::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Nx08s::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Nx08s::quarksFolderPath()
    def self.quarksFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/Nx50s-quarks"
    end

    # Nx08s::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{Nx08s::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Nx08s::items()
    def self.items()
        LucilleCore::locationsAtFolder(Nx08s::itemsFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|x1, x2|  x1["unixtime"] <=> x2["unixtime"]}
    end

    # Nx08s::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = LucilleCore::timeStringL22()

        unixtime     = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        axiomId = Quarks::interactivelyCreateNewAxiom_EchoIdOrNull(Nx08s::quarksFolderPath(), LucilleCore::timeStringL22())

        item = {
              "uuid"         => uuid,
              "unixtime"     => unixtime,
              "description"  => description,
              "axiomId"      => axiomId
            }

        Nx08s::commitItemToDisk(item)

        item
    end

    # Nx08s::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Nx08s::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Nx08s::issueItemUsingLocation(location)
    def self.issueItemUsingLocation(location)
        uuid        = LucilleCore::timeStringL22()
        description = File.basename(location)
        axiomId     = NxA003::make(Nx50s::quarksFolderPath(), LucilleCore::timeStringL22(), location)
        Nx08s::commitItemToDisk({
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "axiomId"     => axiomId,
        })
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx08s::issueNewItemFromLine(line)
    def self.issueNewItemFromLine(line)
        uuid = LucilleCore::timeStringL22()
        item = {
          "uuid"        => uuid,
          "unixtime"    => Time.new.to_f,
          "description" => line,
          "axiomId"     => nil
        }
        Nx08s::commitItemToDisk(item)
        Nx08s::getItemByUUIDOrNull(uuid)
    end


    # -------------------------------------
    # Operations

    # Nx08s::getItemType(item)
    def self.getItemType(item)
        type = KeyValueStore::getOrNull(nil, "6f3abff4-7686-454d-8190-8b0ba983ab14:#{item["uuid"]}")
        return type if type
        type1 = Quarks::contentTypeOrNull(Nx08s::quarksFolderPath(), item["axiomId"])
        type2 = type1 || "line"
        KeyValueStore::set(nil, "6f3abff4-7686-454d-8190-8b0ba983ab14:#{item["uuid"]}", type2)
        type2
    end

    # Nx08s::toString(item)
    def self.toString(item)
        "[asap] (#{item["date"]}) #{item["description"]} (#{Nx08s::getItemType(item)})"
    end

    # Nx08s::accessContent(item)
    def self.accessContent(item)
        if item["axiomId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        Quarks::accessWithOptionToEdit(Nx08s::quarksFolderPath(), item["axiomId"])
    end

    # Nx08s::accessContentsIfContents(item)
    def self.accessContentsIfContents(item)
        return if item["axiomId"].nil?
        Quarks::accessWithOptionToEdit(Nx08s::quarksFolderPath(), item["axiomId"])
    end

    # Nx08s::run(item)
    def self.run(item)
        uuid = item["uuid"]

        puts "running #{Nx08s::toString(item)}".green
        puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow
        puts "Starting at #{Time.new.to_s}"

        domain = Domains::interactivelyGetDomainForItemOrNull(uuid, Nx08s::toString(item))
        nxball = NxBalls::makeNxBall([uuid].compact)

        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end
            }
        }

        puts "note:\n#{StructuredTodoTexts::getNoteOrNull(item["uuid"])}".green

        Nx08s::accessContentsIfContents(item)

        loop {

            system("clear")

            puts "running #{Nx08s::toString(item)}".green
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(item["uuid"])}".green

            puts "access | <datecode> | note | [] | exit | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            if Interpreting::match("access", command) then
                Nx08s::accessContent(item)
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

            if Interpreting::match("exit", command) then
                return
            end

            if Interpreting::match("destroy", command) then
                Quarks::destroy(Nx08s::quarksFolderPath(), item["axiomId"])
                Nx08s::destroy(item)
                break
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Nx08s::itemToNS16(item)
    def self.itemToNS16(item)
        {
            "uuid"        => item["uuid"],
            "announce"    => Nx08s::toString(item),
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Nx08s::run(item)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx08s::toString(item)}' ? ", true) then
                        Nx08s::destroy(item)
                    end
                end
            },
            "run" => lambda {
                Nx08s::run(item)
            }
        }
    end

    # Nx08s::ns16s()
    def self.ns16s()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Nx08 Inbox").each{|location|
            puts "[inbox] #{location}"
            Nx08s::issueItemUsingLocation(location)
            LucilleCore::removeFileSystemLocation(location)
            sleep 1
        }


        Nx08s::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| Nx08s::itemToNS16(item) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
            .select{|ns16| DoNotShowUntil::isVisible(ns16["uuid"]) }
    end

    # Nx08s::main()
    def self.main()
        loop {
            system("clear")

            items = Nx08s::items()
                        .sort{|i1, i2| i1["date"] <=> i2["date"] }

            items.each_with_index{|item, indx| 
                puts "[#{indx}] #{Nx08s::toString(item)}"
            }

            puts "<item index> | (empty) # exit".yellow
            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                item = items[indx]
                next if item.nil?
                Nx08s::run(item)
            end

            Interpreters::mainMenuInterpreter(command)
        }
    end

    # Nx08s::nx19s()
    def self.nx19s()
        Nx08s::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx08s::toString(item),
                "lambda"   => lambda { Nx08s::run(item) }
            }
        }
    end
end
