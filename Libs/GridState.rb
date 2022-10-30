
# encoding: UTF-8

class GridState

    # GridState::gridStateTypes()
    def self.gridStateTypes()
        ["null", "text", "url", "file", "NxDirectoryContents", "Dx8Unit", "unique-string"]
    end

    # GridState::interactivelySelectGridStateTypeOrNull()
    def self.interactivelySelectGridStateTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("grid state type", GridState::gridStateTypes())
    end

    # GridState::nullGridState() # GridState
    def self.nullGridState()
        state = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "GridState",
            "unixtime" => Time.new.to_f,
            "datetime" => Time.new.utc.iso8601,
            "type"     => "null"
        }
        FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
        return state
    end

    # GridState::textGridState(text) # GridState
    def self.textGridState(text)
        state = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "GridState",
            "unixtime" => Time.new.to_f,
            "datetime" => Time.new.utc.iso8601,
            "type"     => "text",
            "text"     => text
        }
        FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
        return state
    end

    # GridState::urlGridState(url) # GridState
    def self.urlGridState(url)
        state = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "GridState",
            "unixtime" => Time.new.to_f,
            "datetime" => Time.new.utc.iso8601,
            "type"     => "url",
            "url"      => url
        }
        FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
        return state
    end

    # GridState::fileGridState(filepath) # GridState
    def self.fileGridState(filepath)
        raise "(error: EA566981-DC21-40FF-B6B0-382974852D4F)" if !File.exists?(filepath)

        operator = Elizabeth4.new()
        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]

        {
            "uuid"            => SecureRandom.uuid,
            "mikuType"        => "GridState",
            "unixtime"        => Time.new.to_f,
            "datetime"        => Time.new.utc.iso8601,
            "type"            => "file",
            "dottedExtension" => dottedExtension,
            "nhash"           => nhash,
            "parts"           => parts
        }
    end

    # GridState::locationToNxDirectoryContentsRootnhashes(location)
    def self.locationToNxDirectoryContentsRootnhashes(location)
        if !File.exists?(location) then
            raise "(error: b10498fc-8b94-418b-a00d-a8ea7d922e17) #{location}"
        end
        if !File.directory?(location) then
            raise "(error: 1765ea10-524b-45af-a1a9-6ab6b5c664cf) #{location}"
        end
        LucilleCore::locationsAtFolder(location)
            .map{|loc| AionCore::commitLocationReturnHash(Elizabeth4.new(), loc) }
    end

    # GridState::directoryPathToNxDirectoryContentsGridState(location) # GridState
    def self.directoryPathToNxDirectoryContentsGridState(location)
        raise "(error: EA566981-DC21-40FF-B6B0-382974852D4F) location: #{location}" if !File.exists?(location)
        raise "(error: 20BD1C67-CD62-4F2C-BB10-7398206BE2E4) location: #{location}" if !File.directory?(location)

        rootnhashes = GridState::locationToNxDirectoryContentsRootnhashes(location)
        state = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "GridState",
            "unixtime"    => Time.new.to_f,
            "datetime"    => Time.new.utc.iso8601,
            "type"        => "NxDirectoryContents",
            "rootnhashes" => rootnhashes
        }
        FileSystemCheck::fsck_GridState(state, SecureRandom.hex, false)
        return state
    end

    # GridState::interactivelyBuildGridStateOrNull() # GridState
    def self.interactivelyBuildGridStateOrNull()
        type = GridState::interactivelySelectGridStateTypeOrNull()
        return nil if type.nil?

        if type == "null" then
            state = GridState::nullGridState()
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
        end

        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            return GridState::textGridState(text)
        end

        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return GridState::urlGridState(url)
        end

        if type == "file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return nil if !File.file?(location)
            filepath = location
            state = GridState::fileGridState(filepath)
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
        end

        if type == "NxDirectoryContents" then
            parentlocation = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return GridState::directoryPathToNxDirectoryContentsGridState(parentlocation)
        end

        if type == "Dx8Unit" then
            unitId = LucilleCore::askQuestionAnswerAsString("unitId (empty to abort): ")
            return nil if unitId == ""
            state = {
                "uuid"       => SecureRandom.uuid,
                "mikuType"   => "GridState",
                "unixtime"   => Time.new.to_f,
                "datetime"   => Time.new.utc.iso8601,
                "type"       => "Dx8Unit",
                "unitId"     => unitId
            }
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
        end

        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("uniquestring (empty to abort): ")
            return nil if uniquestring == ""
            state = {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "GridState",
                "unixtime"     => Time.new.to_f,
                "datetime"     => Time.new.utc.iso8601,
                "type"         => "unique-string",
                "uniquestring" => uniquestring
            }
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
        end
    end

    # Data

    # GridState::toString(state)
    def self.toString(state)
        "#{state["type"]}"
    end

    # Operations

    # GridState::exportNxDirectoryContentsRootsAtFolder(rootnhashes, exportFolder)
    def self.exportNxDirectoryContentsRootsAtFolder(rootnhashes, exportFolder)
        if !File.exists?(exportFolder) then
            raise "(error: d5574c5e-3ab0-458c-98e2-331278e4fb32) cannot see exportFolder: #{exportFolder}"
        end
        if !File.directory?(exportFolder) then
            raise "(error: 7AA14FAC-ECC1-4B1F-94FF-969B8261A2D8) exportFolder is not a directory: #{exportFolder}"
        end
        
        # Cleaning 
        LucilleCore::locationsAtFolder(exportFolder).each{|l| LucilleCore::removeFileSystemLocation(l) }

        # Exporting
        rootnhashes.each{|rootnhash|
            Nx113Access::accessAionPointAtExportDirectory(rootnhash, exportFolder)
        }
    end

    # GridState::exportStateAtFolder(state, folder)
    def self.exportStateAtFolder(state, folder)

        LucilleCore::locationsAtFolder(folder)
            .each{|loc| LucilleCore::removeFileSystemLocation(loc) }

        type = state["type"]

        if type == "null" then
            File.touch("#{folder}/null")
            return
        end

        if type == "text" then
            text = state["text"]
            File.open("#{folder}/text.txt"){|f| f.puts(text) }
        end

        if type == "url" then
            url = state["url"]
            File.open("#{folder}/url.txt"){|f| f.puts(url) }
        end

        if type == "file" then
            dottedExtension = state["dottedExtension"]
            nhash           = state["nhash"]
            parts           = state["parts"]
            operator        = Elizabeth4.new()
            filepath        = "#{folder}/#{nhash}#{dottedExtension}"
            File.open(filepath, "w"){|f|
                parts.each{|nhash|
                    blob = operator.getBlobOrNull(nhash)
                    raise "(error: 13709695-3dca-493b-be46-62d4ef6cf18f)" if blob.nil?
                    f.write(blob)
                }
            }
        end

        if type == "NxDirectoryContents" then
            GridState::exportNxDirectoryContentsRootsAtFolder(state["rootnhashes"], folder)
        end

        if type == "Dx8Unit" then
            unitId = state["unitId"]
            File.open("#{folder}/unitId.txt"){|f| f.puts(unitId) }
        end

        if type == "unique-string" then
            uniquestring = state["uniquestring"]
            File.open("#{folder}/uniquestring.txt"){|f| f.puts(uniquestring) }
        end
    end

    # GridState::access(state)
    def self.access(state)

        type = state["type"]

        if type == "null" then
            return nil
        end

        if type == "text" then
            CommonUtils::accessText(state["text"])
        end

        if type == "url" then
            url = state["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
        end

        if type == "file" then
            dottedExtension = state["dottedExtension"]
            nhash           = state["nhash"]
            parts           = state["parts"]
            operator        = Elizabeth4.new()
            filepath        = "#{ENV['HOME']}/Desktop/#{nhash}#{dottedExtension}"
            File.open(filepath, "w"){|f|
                parts.each{|nhash|
                    blob = operator.getBlobOrNull(nhash)
                    raise "(error: 13709695-3dca-493b-be46-62d4ef6cf18f)" if blob.nil?
                    f.write(blob)
                }
            }
            system("open '#{filepath}'")
            puts "Item exported at #{filepath}"
            LucilleCore::pressEnterToContinue()
        end

        if type == "NxDirectoryContents" then
            exportFolder = "#{ENV['HOME']}/Desktop/NxDirectoryContents-#{SecureRandom.hex(4)}"
            FileUtils.mkdir(exportFolder)
            GridState::exportNxDirectoryContentsRootsAtFolder(state["rootnhashes"], exportFolder)
            puts "State exported at #{exportFolder}"
            LucilleCore::pressEnterToContinue()
        end

        if type == "Dx8Unit" then
            unitId = state["unitId"]
            Dx8Units::access(unitId)
        end

        if type == "unique-string" then
            uniquestring = state["uniquestring"]
            UniqueStrings::findAndAccessUniqueString(uniquestring)
        end
    end

    # GridState::edit(state) # GridState or null
    def self.edit(state)

        type = state["type"]

        if type == "null" then
            return nil
        end

        if type == "text" then
            text1 = state["text"]
            text2 = CommonUtils::editTextSynchronously(text1)
            if text2 != text1 then
                return GridState::textGridState(text2)
            else
                return nil
            end
        end

        if type == "url" then
            puts "current url: #{state["url"]}"
            url = LucilleCore::askQuestionAnswerAsString("new url: ")
            return GridState::urlGridState(url)
        end

        if type == "url" then
            puts "current url: #{state["url"]}"
            url = LucilleCore::askQuestionAnswerAsString("new url: ")
            return GridState::urlGridState(url)
        end

        if type == "file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return nil if !File.file?(location)
            filepath = location
            state = GridState::fileGridState(filepath)
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
        end

        if type == "NxDirectoryContents" then
            exportFolder = "#{ENV['HOME']}/Desktop/NxDirectoryContents-#{SecureRandom.hex(4)}"
            FileUtils.mkdir(exportFolder)
            GridState::exportNxDirectoryContentsRootsAtFolder(state["rootnhashes"], exportFolder)
            puts "State exported at #{exportFolder}"
            LucilleCore::pressEnterToContinue()

            return GridState::directoryPathToNxDirectoryContentsGridState(exportFolder)
        end

        if type == "Dx8Unit" then
            unitId = LucilleCore::askQuestionAnswerAsString("unitId (empty to abort): ")
            return nil if unitId == ""
            state = {
                "uuid"       => SecureRandom.uuid,
                "mikuType"   => "GridState",
                "type"       => "Dx8Unit",
                "unitId"     => unitId
            }
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
        end

        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("uniquestring (empty to abort): ")
            return nil if uniquestring == ""
            state = {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "GridState",
                "type"         => "unique-string",
                "uniquestring" => uniquestring
            }
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
        end
    end

end
