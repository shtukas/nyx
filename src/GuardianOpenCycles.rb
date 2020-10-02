# encoding: UTF-8

=begin

    GuardianOpenCycles
    
    A Guardian Work FS Item is any element of the OpenCycles folder, meaning any file or folder. 
    For the moment we are assuming that they are either text files or folder.
    
    Each element has the following attributes
        - location : full location to the file
        - ordinal : the two digits number that starts the file name
        - filname (without the first two digits numbers and without.txt if a text file)

    The operations are
        - reordinal: Set a new ordinal (which must be an integer)
        - renaming: Set a new main body for the name

    The landing of the app
        - lists the elements in the folder, in order of ordinal (which is always the filename order)
        - let set a new ordinal
        - let reset a name
        - let create a new element (text file or folder)


    Item {
        "location" : String
        "ordinal"  : String, Length 2
        "name"     : String (without extension if text file)
    }

    {
        "location": "/Users/pascal/Galaxy/Current/The Guardian/OpenCycles/00 In review Interactive atoms.txt",
        "ordinal": "00",
        "name": "In review Interactive atoms"
    },
    {
        "location": "/Users/pascal/Galaxy/Current/The Guardian/OpenCycles/01 Audio Atom",
        "ordinal": "01",
        "name": "Audio Atom"
    }

=end

class GOCItemManager

    # GOCItemManager::openCyclesFilepath()
    def self.openCyclesFilepath()
        "/Users/pascal/Galaxy/Current/The Guardian/OpenCycles.txt"
    end

    # GOCItemManager::openCyclesFolderPath()
    def self.openCyclesFolderPath()
        "/Users/pascal/Galaxy/Current/The Guardian/OpenCycles"
    end

    # GOCItemManager::itemsLocations()
    def self.itemsLocations()
        LucilleCore::locationsAtFolder(GOCItemManager::openCyclesFolderPath())
    end

    # GOCItemManager::locationToItemName(location)
    def self.locationToItemName(location)
        basename = File.basename(location)
        if File.file?(location) then
            basename = basename[2, basename.size].strip
            basename[0, basename.size-4]
        else
            basename[2, basename.size].strip
        end
    end

    # GOCItemManager::locationToItem(location)
    def self.locationToItem(location)
        {
            "location" => location,
            "ordinal"  => File.basename(location)[0, 2],
            "name"     => locationToItemName(location)
        }
    end

    # GOCItemManager::items()
    def self.items()
        GOCItemManager::itemsLocations()
            .map{|location|
                GOCItemManager::locationToItem(location)
            }
    end

    # GOCItemManager::itemToString(item)
    def self.itemToString(item)
        "[#{item["ordinal"]}] #{item["name"]}"
    end

    # GOCItemManager::selectItemOrNull()
    def self.selectItemOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item", GOCItemManager::items(), lambda{ |item| GOCItemManager::itemToString(item) })
    end

    # GOCItemManager::openItem(item)
    def self.openItem(item)

        if item["location"][-4, 4] == ".txt" then
            # We have a text file
            system("open '#{item["location"]}'")
            LucilleCore::pressEnterToContinue()
            return
        end

        # By this point we assume that it's a folder
        system("open '#{item["location"]}'")
        LucilleCore::pressEnterToContinue()
        system("open '#{item["location"]}'")
    end

    # GOCItemManager::renameItem(item)
    def self.renameItem(item)
        location1 = item["location"]
        ordinal = item["ordinal"]
        puts "new name:"
        newname = Miscellaneous::editTextSynchronously(item["name"]).strip
        return if newname == item["name"]
        suffix  = (item["location"][-4, 4] == ".txt") ? ".txt" : ""
        filename2 = "#{ordinal} #{newname}#{suffix}"
        location2 = "#{GOCItemManager::openCyclesFolderPath()}/#{filename2}"
        FileUtils.mv(location1, location2)
    end

    # GOCItemManager::reordinalItem(item)
    def self.reordinalItem(item)
        location1 = item["location"]
        newordinal = LucilleCore::askQuestionAnswerAsString("new ordinal (2 digits): ")
        suffix  = (item["location"][-4, 4] == ".txt") ? ".txt" : ""
        filename2 = "#{newordinal} #{item["name"]}#{suffix}"
        location2 = "#{GOCItemManager::openCyclesFolderPath()}/#{filename2}"
        FileUtils.mv(location1, location2)
    end

    # GOCItemManager::itemLanding(item)
    def self.itemLanding(item)
        loop {
            system("clear")

            puts GOCItemManager::itemToString(item)

            ms = LCoreMenuItemsNX1.new()
            puts ""

            ms.item("open".yellow, lambda { 
                GOCItemManager::openItem(item)
            })
            ms.item("rename".yellow, lambda { 
                GOCItemManager::renameItem(item)
            })
            ms.item("re-ordinal".yellow, lambda { 
                GOCItemManager::reordinalItem(item)
            })

            puts ""
            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end

class GuardianOpenCycles

    # We provide
    #    1. A Catalyst object driven by a bank recovering value.
    #    2. A dedicated command line tool.
    #    3. Specific manipulations for on disk mirroring.

    # GuardianOpenCycles::uuid()
    def self.uuid()
        "5c4e1873-d511-474d-8562-073c0f08b536"
    end

    # GuardianOpenCycles::targetTimeInHours()
    def self.targetTimeInHours()
        7
    end

    # GuardianOpenCycles::metric()
    def self.metric()
        uuid = GuardianOpenCycles::uuid()
        return 1 if Runner::isRunning?(uuid)
        recoveredTimeInHours = BankExtended::recoveredDailyTimeInHours(uuid)
        (recoveredTimeInHours < GuardianOpenCycles::targetTimeInHours()) ? 0.70 : 0
    end

    # GuardianOpenCycles::start()
    def self.start()
        Runner::start(GuardianOpenCycles::uuid())
    end

    # GuardianOpenCycles::stop()
    def self.stop()
        timespanInSeconds =  Runner::stop(GuardianOpenCycles::uuid())
        return if timespanInSeconds.nil?
        Bank::put(GuardianOpenCycles::uuid(), timespanInSeconds)
    end

    # GuardianOpenCycles::toString()
    def self.toString()
        uuid = GuardianOpenCycles::uuid()
        ratio = BankExtended::recoveredDailyTimeInHours(GuardianOpenCycles::uuid()).to_f/GuardianOpenCycles::targetTimeInHours()
        runningFor = Runner::isRunning?(uuid) ? " (running for #{((Runner::runTimeInSecondsOrNull(uuid) || 0).to_f/60).round(2)} mins)" : ""
        "Guardian Work (#{"%.2f" % (100*ratio)} %)#{runningFor}"
    end

    # GuardianOpenCycles::catalystObjects()
    def self.catalystObjects()
        uuid = GuardianOpenCycles::uuid()
        object = {
            "uuid"             => uuid,
            "body"             => GuardianOpenCycles::toString(),
            "metric"           => GuardianOpenCycles::metric(),
            "execute"          => lambda { |command| GuardianOpenCycles::program(command) },
            "isRunning"        => Runner::isRunning?(uuid),
            "isRunningForLong" => (Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600
        }
        [ object ]
    end

    # GuardianOpenCycles::program(command)
    def self.program(command)
        if command == "c2c799b1-bcb9-4963-98d5-494a5a76e2e6" then
            uuid = GuardianOpenCycles::uuid()
            Runner::isRunning?(uuid) ? GuardianOpenCycles::stop() : GuardianOpenCycles::start()
            return
        end

        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            puts GuardianOpenCycles::toString().green

            puts ""
            puts "----------------------------------------------------------------------------"
            puts IO.read(GOCItemManager::openCyclesFilepath()).lines.first(10).join()
            puts ""
            ms.item("edit".yellow, lambda { 
                system("open '#{GOCItemManager::openCyclesFilepath()}'")
            })
            ms.item("[]".yellow, lambda { 
                Miscellaneous::applyNextTransformationToFile(GOCItemManager::openCyclesFilepath())
            })
            puts "----------------------------------------------------------------------------"

            puts ""
            GOCItemManager::items().each{|item|
                ms.item(GOCItemManager::itemToString(item), lambda { 
                    GOCItemManager::itemLanding(item)
                })
            }

            puts ""
            if Runner::isRunning?(GuardianOpenCycles::uuid()) then
                ms.item("stop".yellow, lambda { GuardianOpenCycles::stop() })
            else
                ms.item("start".yellow, lambda { GuardianOpenCycles::start() })
            end

            ms.item("add time".yellow, lambda { 
                timeInHours = LucilleCore::askQuestionAnswerAsString("time (in hours): ").to_f
                timespanInSeconds = timeInHours*3600
                Bank::put(GuardianOpenCycles::uuid(), timespanInSeconds)
            })

            ms.item("open folder".yellow, lambda { 
                system("open '#{GOCItemManager::openCyclesFolderPath()}'")
            })

            puts ""
            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
