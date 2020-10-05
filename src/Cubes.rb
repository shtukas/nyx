
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

    # CubeFolderManager::reordinalItem(cube, item)
    def self.reordinalItem(cube, item)
        location1 = item["location"]
        newordinal = LucilleCore::askQuestionAnswerAsString("new ordinal (2 digits): ")
        suffix  = (item["location"][-4, 4] == ".txt") ? ".txt" : ""
        filename2 = "#{newordinal} #{item["name"]}#{suffix}"
        location2 = "#{cube["location"]}/#{filename2}"
        FileUtils.mv(location1, location2)
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
                CubeFolderManager::reordinalItem(cube, item)
            })

            puts ""
            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
