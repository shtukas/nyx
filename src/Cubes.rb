
# encoding: UTF-8

=begin
{
    "uuid"          : String
    "nyxNxSet"      : "06071daa-ec51-4c19-a4b9-62f39bb2ce4f"
    "unixtime"      : Float # Unixtime with decimals
    "description"   : String
    "location"      : String # Folder path to the listing
}
=end

class Cubes

    # Cubes::issueCube(description, location)
    def self.issueCube(description, location)
        cube = {
            "uuid"          => SecureRandom.hex,
            "nyxNxSet"      => "06071daa-ec51-4c19-a4b9-62f39bb2ce4f",
            "unixtime"      => Time.new.to_f, # Unixtime with decimals
            "description"   => description,
            "location"      => location # Folder path to the listing
        }
        NyxObjects2::put(cube)
        cube
    end

    # Cubes::toString(cube)
    def self.toString(cube)
        "[cube] #{cube["description"]}"
    end

    # Cubes::cubes()
    def self.cubes()
        NyxObjects2::getSet("06071daa-ec51-4c19-a4b9-62f39bb2ce4f")
    end

    # Cubes::cubeLanding(cube)
    def self.cubeLanding(cube)
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            puts Cubes::toString(cube).green
            puts "uuid: #{cube["uuid"]}"

            organiserFilepath = "#{cube["location"]}/00.txt"

            puts ""

            if File.exists?(organiserFilepath) then
                puts IO.read(organiserFilepath).lines.first(10).join().strip.green
                puts ""
                ms.item("edit".yellow, lambda { 
                    system("open '#{organiserFilepath}'")
                })
                ms.item("[]".yellow, lambda { 
                    Miscellaneous::applyNextTransformationToFile(organiserFilepath)
                })
            else
                ms.item("Make top text file".yellow, lambda { 
                    FileUtils.touch(organiserFilepath)
                    system("open '#{organiserFilepath}'")
                })
            end

            puts ""

            CubeFolderManager::items(cube).each{|item|
                ms.item(CubeFolderManager::itemToString(item), lambda { 
                    CubeFolderManager::itemLanding(cube, item)
                })
            }

            puts ""

            ms.item("open folder".yellow, lambda { 
                system("open '#{cube["location"]}'")
            })

            puts ""
            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # Cubes::cubesDive()
    def self.cubesDive()
        loop {
            system("clear")

            mx = LCoreMenuItemsNX1.new()

            Cubes::cubes().each{|cube|
                mx.item(Cubes::toString(cube), lambda {
                    Cubes::cubeLanding(cube)
                })
            }

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Cubes::selectCubeOrNull()
    def self.selectCubeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cube", Cubes::cubes(), lambda{ |cube| Cubes::toString(cube) })
    end
end

# --------------------------------------------------------

=begin

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

class CubeFolderManager

    # CubeFolderManager::locationToItemName(location)
    def self.locationToItemName(location)
        basename = File.basename(location)
        if File.file?(location) then
            basename = basename[2, basename.size].strip
            basename[0, basename.size-4]
        else
            basename[2, basename.size].strip
        end
    end

    # CubeFolderManager::locationToItem(location)
    def self.locationToItem(location)
        {
            "location" => location,
            "ordinal"  => File.basename(location)[0, 2],
            "name"     => locationToItemName(location)
        }
    end

    # CubeFolderManager::items(cube)
    def self.items(cube)
        LucilleCore::locationsAtFolder(cube["location"])
            .select{|location| File.basename(location) != "00.txt" }
            .map{|location|
                CubeFolderManager::locationToItem(location)
            }
    end

    # CubeFolderManager::itemToString(item)
    def self.itemToString(item)
        "[#{item["ordinal"]}] #{item["name"]}"
    end

    # CubeFolderManager::selectItemOrNull(cube)
    def self.selectItemOrNull(cube)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item", CubeFolderManager::items(cube), lambda{ |item| CubeFolderManager::itemToString(item) })
    end

    # CubeFolderManager::openItem(item)
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

    # CubeFolderManager::renameItem(cube, item)
    def self.renameItem(cube, item)
        location1 = item["location"]
        ordinal = item["ordinal"]
        puts "new name:"
        newname = Miscellaneous::editTextSynchronously(item["name"]).strip
        return if newname == item["name"]
        suffix  = (item["location"][-4, 4] == ".txt") ? ".txt" : ""
        filename2 = "#{ordinal} #{newname}#{suffix}"
        location2 = "#{cube["location"]}/#{filename2}"
        FileUtils.mv(location1, location2)
    end

    # CubeFolderManager::reordinalItemWithSpecifiedTargetOrdinal(cube, item, newordinal)
    def self.reordinalItemWithSpecifiedTargetOrdinal(cube, item, newordinal)
        location1 = item["location"]
        suffix  = (item["location"][-4, 4] == ".txt") ? ".txt" : ""
        filename2 = "#{newordinal} #{item["name"]}#{suffix}"
        location2 = "#{cube["location"]}/#{filename2}"
        FileUtils.mv(location1, location2)
    end

    # CubeFolderManager::reordinalItemInteractively(cube, item)
    def self.reordinalItemInteractively(cube, item)
        newordinal = LucilleCore::askQuestionAnswerAsString("new ordinal (2 digits): ")
        CubeFolderManager::reordinalItemWithSpecifiedTargetOrdinal(cube, item, newordinal)
    end

    # CubeFolderManager::itemLanding(cube, item)
    def self.itemLanding(cube, item)
        loop {
            system("clear")

            puts CubeFolderManager::itemToString(item)

            ms = LCoreMenuItemsNX1.new()
            puts ""

            ms.item("open".yellow, lambda { 
                CubeFolderManager::openItem(item)
            })
            ms.item("rename".yellow, lambda { 
                CubeFolderManager::renameItem(cube, item)
            })
            ms.item("re-ordinal".yellow, lambda { 
                CubeFolderManager::reordinalItemInteractively(cube, item)
            })

            puts ""
            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # CubeFolderManager::ensureSpaceAtOrdinal(cube, ordinal)
    def self.ensureSpaceAtOrdinal(cube, ordinal)
        items = CubeFolderManager::items(cube)
        itemsAtOrdinal = items.select{|item| item["ordinal"] == ordinal }
        return if itemsAtOrdinal.empty?
        items
            .select{|item| item["ordinal"] >= ordinal }
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .reverse
            .each{|item|
                newordinal = CubeTransformers::increase2DigitOrdinalBy1(item["ordinal"])
                CubeFolderManager::reordinalItemWithSpecifiedTargetOrdinal(cube, item, newordinal)
            }
    end
end

class CubeTransformers

    # CubeTransformers::increase2DigitOrdinalBy1(ordinal)
    def self.increase2DigitOrdinalBy1(ordinal)
        (ordinal.to_i + 1).to_s.rjust(2, "0")
    end

    # CubeTransformers::sendDatapointToCubeSystem(datapoint)
    def self.sendDatapointToCubeSystem(datapoint)

        # What is happening here:
        #    1. We select a Cube
        #    2. We select a position for it inside that Cube folder
        #    3. We make some space for it inside that Cube
        #    4. We Create the file/folder
        #    5. We delete the datapoint

        puts "-> select a cube:"
        cube = Cubes::selectCubeOrNull()
        return if cube.nil?
        puts JSON.pretty_generate(cube)

        puts "-> select target position (null for next):"
        item = CubeFolderManager::selectItemOrNull(cube)
        if item then
            puts JSON.pretty_generate(item)
            targetOrdinal = item["ordinal"]
        else
            maxOrdinal = (["00"] + CubeFolderManager::items(cube).map{|item| item["ordinal"] }).compact.max
            targetOrdinal = CubeTransformers::increase2DigitOrdinalBy1(maxOrdinal)
        end

        CubeFolderManager::ensureSpaceAtOrdinal(cube, targetOrdinal)

        if datapoint["type"] == "line" then
            filename = "#{targetOrdinal} LINE-#{datapoint["uuid"]}.txt"
            filepath = "#{cube["location"]}/#{filename}"
            File.open(filepath, "w"){|f| f.puts(datapoint["line"]) }
        end
        if datapoint["type"] == "url" then
            filename = "#{targetOrdinal} URL-#{datapoint["uuid"]}.txt"
            filepath = "#{cube["location"]}/#{filename}"
            File.open(filepath, "w"){|f| f.puts(datapoint["url"]) }
        end
        if datapoint["type"] == "NyxFile" then
            nyxfilelocation = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            nyxfile_extension_withDot = File.extname(nyxfilelocation)
            itemFilename = "#{targetOrdinal} FormerNyxFile-#{datapoint["uuid"]}#{nyxfile_extension_withDot}"
            itemFilepath = "#{cube["location"]}/#{itemFilename}"
            FileUtils.mv(nyxfilelocation, itemFilepath)
        end
        if datapoint["type"] == "NyxDirectory" then
            nyxfilelocation = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            itemFoldername = "#{targetOrdinal} FormerNyxDirectory-#{datapoint["uuid"]}"
            itemFolderpath = "#{cube["location"]}/#{itemFoldername}"
            FileUtils.mv(nyxfilelocation, itemFolderpath)
        end
        if datapoint["type"] == "NyxFSPoint001" then
            nyxfilelocation = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            system("open '#{File.dirname(nyxfilelocation)}'")
            itemFoldername = "#{targetOrdinal} FormerNyxFSPoint001-#{datapoint["uuid"]}"
            itemFolderpath = "#{cube["location"]}/#{itemFoldername}"
            FileUtils.mkdir(itemFolderpath)
            system("open '#{itemFolderpath}'")
            puts "You need to move the files manually"
            LucilleCore::pressEnterToContinue()
            FileUtils.rm(nyxfilelocation)
        end

        NyxObjects2::destroy(datapoint)
    end

    # CubeTransformers::sendLineToCubeSystem(line) # Boolean
    def self.sendLineToCubeSystem(line)

        # What is happening here:
        #    1. We select a Cube
        #    2. We select a position for it inside that Cube folder
        #    3. We make some space for it inside that Cube
        #    4. We Create the file/folder
        #    5. We delete the datapoint

        puts "-> select a cube:"
        cube = Cubes::selectCubeOrNull()
        return false if cube.nil?
        puts JSON.pretty_generate(cube)

        puts "-> select target position (null for next):"
        item = CubeFolderManager::selectItemOrNull(cube)
        if item then
            puts JSON.pretty_generate(item)
            targetOrdinal = item["ordinal"]
        else
            maxOrdinal = (["00"] + CubeFolderManager::items(cube).map{|item| item["ordinal"] }).compact.max
            targetOrdinal = CubeTransformers::increase2DigitOrdinalBy1(maxOrdinal)
        end

        CubeFolderManager::ensureSpaceAtOrdinal(cube, targetOrdinal)

        filename = "#{targetOrdinal} LINE-#{SecureRandom.hex}.txt"
        filepath = "#{cube["location"]}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(line) }

        true
    end
end
