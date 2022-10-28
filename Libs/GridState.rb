
# encoding: UTF-8

class GridState

    # GridState::gridStateTypes()
    def self.gridStateTypes()
        ["text", "url", "file", "NxDirectoryContents", "Dx8Unit", "unique-string"]
    end

    # GridState::interactivelySelectGridStateTypeOrNull()
    def self.interactivelySelectGridStateTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("grid state type", GridState::gridStateTypes())
    end

    # GridState::makeFile(filepath) # GridState
    def self.makeFile(filepath)
        raise "(error: EA566981-DC21-40FF-B6B0-382974852D4F)" if !File.exists?(filepath)

        operator = Elizabeth4.new()
        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]

        {
            "uuid"            => SecureRandom.uuid,
            "mikuType"        => "GridState",
            "type"            => "file",
            "dottedExtension" => dottedExtension,
            "nhash"           => nhash,
            "parts"           => parts
        }
    end

    # GridState::locationToContentsRootnhashes(location)
    def self.locationToContentsRootnhashes(location)
        if !File.exists?(location) then
            raise "(error: b10498fc-8b94-418b-a00d-a8ea7d922e17) #{location}"
        end
        if !File.directory?(location) then
            raise "(error: 1765ea10-524b-45af-a1a9-6ab6b5c664cf) #{location}"
        end
        LucilleCore::locationsAtFolder(location)
            .map{|loc| AionCore::commitLocationReturnHash(Elizabeth4.new(), loc) }
    end

    # GridState::interactivelyBuildGridStateOrNull()
    def self.interactivelyBuildGridStateOrNull()
        type = GridState::interactivelySelectGridStateTypeOrNull()
        return nil if type.nil?

        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            state = {
                "uuid"       => SecureRandom.uuid,
                "mikuType"   => "GridState",
                "type"       => "text",
                "text"       => text
            }
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
        end

        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            state = {
                "uuid"       => SecureRandom.uuid,
                "mikuType"   => "GridState",
                "type"       => "url",
                "url"        => url
            }
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
        end

        if type == "file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return nil if !File.file?(location)
            filepath = location
            state = GridState::makeFile(filepath)
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
        end

        if type == "NxDirectoryContents" then
            parentlocation = CommonUtils::interactivelySelectDesktopLocationOrNull()
            rootnhashes = GridState::locationToContentsRootnhashes(parentlocation)
            state = {
                "uuid"        => SecureRandom.uuid,
                "mikuType"    => "GridState",
                "type"        => "NxDirectoryContents",
                "rootnhashes" => rootnhashes
            }
            FileSystemCheck::fsck_GridState(state, SecureRandom.hex, true)
            return state
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
