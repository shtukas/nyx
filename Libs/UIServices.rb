# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class MetricUtils

    # MetricUtils::unixtimeToMetricShiftIncreasing(unixtime)
    def self.unixtimeToMetricShiftIncreasing(unixtime)
        0.01*Math.exp(-(Time.new.to_i-unixtime).to_f/86400)
    end

    # MetricUtils::datetimeToMetricShiftIncreasing(datetime)
    def self.datetimeToMetricShiftIncreasing(datetime)
        unixtime = DateTime.parse(datetime).to_time.to_i
        MetricUtils::unixtimeToMetricShiftIncreasing(unixtime)
    end

    # MetricUtils::dateToMetricShiftIncreasing(date)
    def self.dateToMetricShiftIncreasing(date)
        datetime = "#{date} 00:00:00 #{Utils::getLocalTimeZone()}"
        MetricUtils::datetimeToMetricShiftIncreasing(datetime)
    end
end

class Fitness
    # Fitness::ns16s()
    def self.ns16s()
        ns16s = JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`)
        ns16s.map{|ns16|
            ns16["access"] = lambda { system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing") }
            ns16
        }
    end
end

class TodoLines

    # TodoLines::ns16s()
    def self.ns16s()
        BTreeSets::values(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2")
            .map{|todo|
                {
                    "uuid"     => todo["uuid"],
                    "announce" => "[todo] #{todo["description"]}",
                    "access"   => lambda {
                        nxball = BankExtended::makeNxBall(["Nx60-69315F2A-BE92-4874-85F1-54F140E3B243"])
                        thr = Thread.new {
                            loop {
                                sleep 60
                                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                                    nxball = BankExtended::upgradeNxBall(nxball, false)
                                end
                            }
                        }
                        if LucilleCore::askQuestionAnswerAsBoolean("done '#{todo["description"]}' ? ") then
                            BTreeSets::destroy(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", todo["uuid"])
                        end
                        thr.exit
                        BankExtended::closeNxBall(nxball, true)
                    },
                    "done"     => lambda {
                        BTreeSets::destroy(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", todo["uuid"])
                    },
                    "metric"   => 0.35 + MetricUtils::unixtimeToMetricShiftIncreasing(todo["unixtime"])
                }

            }
    end
end

class TodoInbox

    # TodoInbox::repositoryFolderpath()
    def self.repositoryFolderpath()
        "/Users/pascal/Desktop/Inbox"
    end

    # TodoInbox::locations()
    def self.locations()
        LucilleCore::locationsAtFolder(TodoInbox::repositoryFolderpath())
    end

    # TodoInbox::getDescriptionOrNull(location)
    def self.getDescriptionOrNull(location)
        return nil if !File.exists?(location)
        KeyValueStore::getOrNull(nil, "ca23acc1-6596-4e8e-b9e7-714ae3c7b0f8:#{location}")
    end

    # TodoInbox::setDescription(location, description)
    def self.setDescription(location, description)
        KeyValueStore::set(nil, "ca23acc1-6596-4e8e-b9e7-714ae3c7b0f8:#{location}", description)
    end

    # TodoInbox::announce(location)
    def self.announce(location)
        description = TodoInbox::getDescriptionOrNull(location)
        if description then
            "[todo] #{description}"
        else
            "[todo] #{File.basename(location)}"
        end
    end

    # TodoInbox::ensureDescription(location)
    def self.ensureDescription(location)
        if TodoInbox::getDescriptionOrNull(location).nil? then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            TodoInbox::setDescription(location, description)
        end
    end

    # TodoInbox::access(location)
    def self.access(location)

        uuid = "#{location}:#{Utils::today()}"

        nxball = BankExtended::makeNxBall(["Nx60-69315F2A-BE92-4874-85F1-54F140E3B243"])

        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = BankExtended::upgradeNxBall(nxball, false)
                end
            }
        }

        loop {

            system("clear")

            break if !File.exist?(location)

            puts location.yellow

            if location.include?("'") then
                puts "Looking at: #{location}"
                if LucilleCore::askQuestionAnswerAsBoolean("remove quote ? ", true) then
                    location2 = location.gsub("'", "-")
                    FileUtils.mv(location, location2)
                    location = location2
                end
            end

            if !location.include?("'") then
                system("open '#{location}'")
            end

            puts "done | open | <datecode> | >nx50s (move to nx50) | exit".yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")
        
            break if command == "exit"

            if Interpreting::match("done", command) then
                LucilleCore::removeFileSystemLocation(location)
                break
            end

            if Interpreting::match("open", command) then
                system("open '#{location}'")
                break
            end

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match(">nx50s", command) then
                nx50 = Nx50s::issueNx50UsingLocation(location)
                nx50["unixtime"] = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)
                CoreDataTx::commit(nx50)
                LucilleCore::removeFileSystemLocation(location)
                break
            end
        }

        if File.exists?(location) and TodoInbox::getDescriptionOrNull(location).nil? then
            TodoInbox::ensureDescription(location)
        end

        thr.exit

        BankExtended::closeNxBall(nxball, true)
    end

    # TodoInbox::ns16s()
    def self.ns16s()
        TodoInbox::locations().map{|location|
            {
                "uuid"     => "#{location}:#{Utils::today()}",
                "announce" => TodoInbox::announce(location),
                "access"   => lambda { TodoInbox::access(location) },
                "done"     => lambda { LucilleCore::removeFileSystemLocation(location) },
                "metric"   => 0.35 + MetricUtils::datetimeToMetricShiftIncreasing(File.mtime(location).to_s)
            }
        }
    end
end

class NS16sOperator

    # NS16sOperator::ns16s()
    def self.ns16s()
        items1 = [
            DetachedRunning::ns16s(),
            PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority Now.txt"),
            TodoInbox::ns16s(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Nx31s::ns16s(),
            Waves::ns16s(),
            Fitness::ns16s(),
            Work::ns16s(),
            Nx50s::ns16s(),
            TodoLines::ns16s(),
            NxFloat::ns16s(),
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .sort{|n1, n2| n1["metric"] <=> n2["metric"] }
    end

end

class UIServices

    # UIServices::programmableListingDisplay(getItems: Lambda: () -> Array[NS16], processItems: Lambda: Array[NS16] -> Status)
    def self.programmableListingDisplay(getItems, processItems)
        loop {
            items = getItems.call()
            status = processItems.call(items)
            raise "error: 2681e316-4a5b-447f-a822-1820355fb0e5" if !["ns:loop", "ns:exit"].include?(status)
            break if status == "ns:exit"
        }
    end

    # UIServices::mainMenuCommands()
    def self.mainMenuCommands()
        "todo | float | wave | ondate | calendar item | Nx50 | floats | waves | ondates | calendar | Nx50s | anniversaries | work-start | work-not-today | work-reset | search | >nyx"
    end

    # UIServices::mainMenuInterpreter(command)
    def self.mainMenuInterpreter(command)

        if Interpreting::match("todo", command) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            todo = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "description" => description
            }
            BTreeSets::set(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", todo["uuid"], todo)
        end

        if Interpreting::match("float", command) then
            float = NxFloat::interactivelyCreateNewOrNull()
            puts JSON.pretty_generate(float)
        end

        if Interpreting::match("wave", command) then
            Waves::issueNewWaveInteractivelyOrNull()
        end

        if Interpreting::match("ondate", command) then
            nx31 = Nx31s::interactivelyIssueNewOrNull()
            puts JSON.pretty_generate(nx31)
        end

        if Interpreting::match("calendar item", command) then
            Calendar::interactivelyIssueNewCalendarItem()
        end

        if Interpreting::match("Nx50", command) then
            nx50 = Nx50s::interactivelyCreateNewOrNull()
            if nx50 then
                puts JSON.pretty_generate(nx50)
            end
        end

        if Interpreting::match("floats", command) then
            puts "floats is not implemented"
            LucilleCore::pressEnterToContinue()
        end

        if Interpreting::match("ondates", command) then
            Nx31s::main()
        end

        if Interpreting::match("anniversaries", command) then
            Anniversaries::main()
        end

        if Interpreting::match("calendar", command) then
            Calendar::main()
        end

        if Interpreting::match("waves", command) then
            Waves::main()
        end

        if Interpreting::match("Nx50s", command) then
            ns16 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", Nx50s::ns16sExtended(), lambda {|ns50| ns50["announce"] })
            return if ns16.nil?
            ns16["access"].call()
        end

        if Interpreting::match("work-start", command) then
            DetachedRunning::issueNew2("Work", Time.new.to_i, ["WORK-E4A9-4BCD-9824-1EEC4D648408"])
        end

        if Interpreting::match("work-not-today", command) then
            KeyValueStore::set(nil, "ce621184-51d7-456a-8ad1-20e7d9acb350:#{Utils::today()}", "ns:false")
        end

        if Interpreting::match("work-reset", command) then
            KeyValueStore::destroy(nil, "ce621184-51d7-456a-8ad1-20e7d9acb350:#{Utils::today()}")
        end

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match(">nyx", command) then
            system("/Users/pascal/Galaxy/Software/Nyx/x-make-new")
        end
    end

    # UIServices::catalystMainInterface()
    def self.catalystMainInterface()
        getItems1 = lambda {
            ns16s = NS16sOperator::ns16s()
            if ns16s.size>0 and ns16s[0]["announce"]=="" then
                ns16s.shift
            end
            ns16s
        }

        getItems2 = lambda {
            NS16sOperator::ns16s()
        }

        processItems = lambda {|items|

            accessItem = lambda { |item| 
                return if item.nil? 
                return if item["access"].nil?
                item["access"].call()
            }

            system("clear")

            vspaceleft = Utils::screenHeight()-6

            puts ""

            items.each_with_index{|item, indx|
                indexStr   = "(#{"%3d" % indx})"
                announce   = "#{indexStr}#{item["metric"] ? " (#{"%3.2f" % item["metric"]})".red : ""} #{item["announce"]}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

            puts [
                "(waves: rt: #{BankExtended::stdRecoveredDailyTimeInHours("WAVES-A81E-4726-9F17-B71CAD66D793").round(2)}) ",
                "(todos: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx60-69315F2A-BE92-4874-85F1-54F140E3B243").round(2)}) ",
                "(Nx50s: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7").round(2)}, #{CoreDataTx::getObjectsBySchema("Nx50").size} items, done: today: #{Nx50s::completionLogSize(1)}, week: #{Nx50s::completionLogSize(7)}, month: #{Nx50s::completionLogSize(30)}) "
            ].join().yellow

            if !items.empty? then
                puts "top : .. | select (<n>) | done (<n>) | hide <n> | <datecode> | exit".yellow
            end
            puts UIServices::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            return "ns:loop" if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                item = items[0]
                return "ns:loop" if item.nil? 
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                puts "Hidden until: #{Time.at(unixtime).to_s}"
                return "ns:loop"
            end

            # -- listing -----------------------------------------------------------------------------

            if Interpreting::match("..", command) then
                accessItem.call(items[0])
                return "ns:loop"
            end

            if (ordinal = Interpreting::readAsIntegerOrNull(command)) then
                accessItem.call(items[ordinal])
                return "ns:loop"
            end

            if Interpreting::match("select *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                accessItem.call(items[ordinal])
                return "ns:loop"
            end

            if Interpreting::match("done", command) then
                item = items[0]
                return "ns:loop" if item.nil? 
                return "ns:loop" if item["done"].nil?
                item["done"].call()
                return "ns:loop"
            end

            if Interpreting::match("hide *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i+3600)
                return "ns:loop"
            end

            if Interpreting::match("done *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                return "ns:loop" if item.nil?
                return "ns:loop" if item["done"].nil?
                item["done"].call()
                return "ns:loop"
            end

            # -- top -----------------------------------------------------------------------------

            if Interpreting::match("[]", command) then
                item = items[0]
                return "ns:loop" if item.nil? 
                return "ns:loop" if item["[]"].nil?
                item["[]"].call()
                return "ns:loop"
            end

            if Interpreting::match("exit", command) then
                return "ns:exit"
            end

            UIServices::mainMenuInterpreter(command)

            "ns:loop"
        }

        UIServices::programmableListingDisplay(getItems2, processItems)
    end
end
