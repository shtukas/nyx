# encoding: UTF-8

class Nx25s

    # Nx25s::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/Nx25s"
    end

    # Nx25s::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Nx25s::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Nx25s::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{Nx25s::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Nx25s::items()
    def self.items()
        LucilleCore::locationsAtFolder(Nx25s::itemsFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|x1, x2|  x1["unixtime"] <=> x2["unixtime"]}
    end

    # Nx25s::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Nx25s::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Makers

    # Nx25s::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = LucilleCore::timeStringL22()

        unixtime     = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()

        item = {
              "uuid"        => uuid,
              "unixtime"    => unixtime,
              "description" => description,
              "coreDataId"  => coreDataId
            }

        Nx25s::commitItemToDisk(item)

        item
    end

    # Nx08s::issueItemUsingURL(url)
    def self.issueItemUsingURL(url)
        uuid        = LucilleCore::timeStringL22()
        unixtime    = Time.new.to_f
        description = url
        coreDataId = CoreData::issueUrlPointDataObjectUsingUrl(url)
        Nx25s::commitItemToDisk({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
        })
        Nx25s::getItemByUUIDOrNull(uuid)
    end

    # Nx25s::issueItemUsingLocation(location)
    def self.issueItemUsingLocation(location)
        uuid        = LucilleCore::timeStringL22()
        description = File.basename(location)
        coreDataId = CoreData::issueAionPointDataObjectUsingLocation(location)
        Nx25s::commitItemToDisk({
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "coreDataId"  => coreDataId,
        })
        Nx50s::getNx50ByUUIDOrNull(uuid)
    end

    # Nx25s::issueNewItemFromLine(line)
    def self.issueNewItemFromLine(line)
        uuid = LucilleCore::timeStringL22()
        item = {
          "uuid"        => uuid,
          "unixtime"    => Time.new.to_f,
          "description" => line,
          "coreDataId"     => nil
        }
        Nx25s::commitItemToDisk(item)
        Nx25s::getItemByUUIDOrNull(uuid)
    end

    # Nx25s::issueItemUsingText(text, unixtime)
    def self.issueItemUsingText(text, unixtime)
        uuid         = LucilleCore::timeStringL22()
        description  = text.strip.lines.first.strip || "todo text @ #{Time.new.to_s}" 
        coreDataId      = CoreData::issueTextDataObjectUsingText(text)
        Nx25s::commitItemToDisk({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
        })
        Nx25s::getItemByUUIDOrNull(uuid)
    end

    # -------------------------------------
    # Operations

    # Nx25s::getItemType(item)
    def self.getItemType(item)
        type = KeyValueStore::getOrNull(nil, "6f3abff4-7686-454d-8190-8b0ba983ab14:#{item["uuid"]}")
        return type if type
        type1 = CoreData::contentTypeOrNull(item["coreDataId"])
        type2 = type1 || "line"
        KeyValueStore::set(nil, "6f3abff4-7686-454d-8190-8b0ba983ab14:#{item["uuid"]}", type2)
        type2
    end

    # Nx25s::toString(item)
    def self.toString(item)
        "[Nx25] #{item["description"]} (#{Nx25s::getItemType(item)})"
    end

    # Nx25s::accessContent(item)
    def self.accessContent(item)
        if item["coreDataId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        CoreData::accessWithOptionToEdit(item["coreDataId"])
    end

    # Nx25s::run(item)
    def self.run(item)
        uuid = item["uuid"]

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

        puts "running #{Nx25s::toString(item)}".green

        Nx25s::accessContent(item)

        actions = [
            "done & destroy",
            "not today",
            "recast as Nx50",
            "recast as Nx51",
            "replace by new Catalyst item"
        ]
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("actions", actions)

        if action == "done & destroy" then
            Nx25s::destroy(item)
        end

        if action == "not today" then
            DoNotShowUntil::setUnixtime(item["uuid"], Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()))
        end

        if action == "recast as Nx50" then
            description = if item["description"].start_with?("Screenshot") then 
                                LucilleCore::askQuestionAnswerAsString("description: ")
                          else
                                item["description"]
                          end
            item = {
                "uuid"        => item["uuid"],
                "unixtime"    => item["unixtime"],
                "description" => item["description"],
                "coreDataId"     => item["coreDataId"]
            }
            Nx50s::commitNx50ToDatabase(item)
            Nx25s::destroy(item)
        end

        if action == "recast as Nx51" then
            description = if item["description"].start_with?("Screenshot") then 
                                LucilleCore::askQuestionAnswerAsString("description: ")
                          else
                                item["description"]
                          end
            item = {
                "uuid"        => item["uuid"],
                "unixtime"    => item["unixtime"],
                "description" => item["description"],
                "coreDataId"     => item["coreDataId"]
            }
            Nx51s::commitItemToDisk(item)
            Nx25s::destroy(item)
        end

        if action == "replace by new Catalyst item" then
            puts Interpreters::mainMenuCommands().yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")
            Interpreters::mainMenuInterpreter(command)
            Nx25s::destroy(item)
        end

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Nx25s::itemToNS16(item)
    def self.itemToNS16(item)
        {
            "uuid"        => item["uuid"],
            "announce"    => Nx25s::toString(item),
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Nx25s::run(item)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx25s::toString(item)}' ? ", true) then
                        Nx25s::destroy(item)
                    end
                end
            },
            "run" => lambda {
                Nx25s::run(item)
            },
            "item" => item
        }
    end

    # Nx25s::ns16s()
    def self.ns16s()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/After Hours, ASAP (Nx25)").each{|location|
            puts "[Nx25] #{location}"
            Nx25s::issueItemUsingLocation(location)
            LucilleCore::removeFileSystemLocation(location)
            sleep 1
        }

        Nx25s::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| Nx25s::itemToNS16(item) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # Nx25s::nx19s()
    def self.nx19s()
        Nx25s::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx25s::toString(item),
                "lambda"   => lambda { Nx25s::run(item) }
            }
        }
    end
end
