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

        axiomId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()

        item = {
              "uuid"         => uuid,
              "unixtime"     => unixtime,
              "description"  => description,
              "axiomId"      => axiomId
            }

        Nx08s::commitItemToDisk(item)

        item
    end

    # Nx08s::destroyItemBuNotTheAxiom(item)
    def self.destroyItemBuNotTheAxiom(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Nx08s::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Nx08s::destroy(item)
    def self.destroy(item)
        Nx08s::destroyItemBuNotTheAxiom(item)
    end

    # Nx08s::issueItemUsingLocation(location)
    def self.issueItemUsingLocation(location)
        uuid        = LucilleCore::timeStringL22()
        description = File.basename(location)
        axiomId     = CoreData::issueAionPointDataObjectUsingLocation(location)
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
        type1 = CoreData::contentTypeOrNull(item["axiomId"])
        type2 = type1 || "line"
        KeyValueStore::set(nil, "6f3abff4-7686-454d-8190-8b0ba983ab14:#{item["uuid"]}", type2)
        type2
    end

    # Nx08s::toString(item)
    def self.toString(item)
        "[ in ] #{item["description"]} (#{Nx08s::getItemType(item)})"
    end

    # Nx08s::accessContent(item)
    def self.accessContent(item)
        if item["axiomId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        Quarks::accessWithOptionToEdit(item["axiomId"])
    end

    # Nx08s::accessContentsIfContents(item)
    def self.accessContentsIfContents(item)
        return if item["axiomId"].nil?
        Quarks::accessWithOptionToEdit(item["axiomId"])
    end

    # Nx08s::run(item)
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

        puts "running #{Nx08s::toString(item)}".green

        Nx08s::accessContentsIfContents(item)

        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("actions", ["done & destroy", "postpone by 1 hour (default)", "postpone by 4 hours", "recast as Nx50", "replace by new Catalyst item"])

        if action == "done & destroy" then
            Nx08s::destroy(item)
        end

        if action.nil? or (action == "postpone by 1 hour") then
            DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_f + 3600)
        end

        if action == "postpone by 4 hours" then
            DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_f + 4*3600)
        end

        if action == "recast as Nx50" then
            domain = Domains::interactivelySelectDomainOrNull() || "eva"
            description = if item["description"].start_with?("Screenshot") then 
                                LucilleCore::askQuestionAnswerAsString("description: ")
                          else
                                item["description"]
                          end
            nx50 = {
                "uuid"        => item["uuid"],
                "unixtime"    => item["unixtime"],
                "description" => item["description"],
                "axiomId"     => item["axiomId"],
                "domain"      => domain
            }
            Nx50s::commitNx50ToDatabase(nx50)
            Domains::setDomainForItem(nx50["uuid"], domain)
            Nx08s::destroyItemBuNotTheAxiom(item)
        end

        if action == "replace by new Catalyst item" then
            puts Interpreters::mainMenuCommands().yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")
            Interpreters::mainMenuInterpreter(command)
            Nx08s::destroy(item)
        end

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
