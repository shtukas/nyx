
# encoding: UTF-8

class CoreData

    # The principal design idea of CoreData is that we refer to specific storage units by 
    # a single string and mutations of the storage unit are transparent to the holder.
    # Issuing another storage unit corresponds to a different string

    # CoreData::payloadTypes()
    def self.payloadTypes()
        ["nyx-directory"]
    end

    # CoreData::interactivelySelectNyxPayloadType()
    def self.interactivelySelectNyxPayloadType()
        types = CoreData::payloadTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("coredata type", types)
    end

    # CoreData::issuePayload(uuid) # payload string
    def self.issuePayload(uuid)
        # This function is called during the making of a new node (or when we are issuing a new payload of an existing node)
        # It does stuff and returns a payload string or null
        payloadType = CoreData::interactivelySelectNyxPayloadType()
        return nil if payloadType.nil?
        if payloadType == "nyx-directory" then
            folderpath = NyxDirectories::makeNewDirectory(uuid)
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
            return "nyx-directory" # The first nyx-directory is a payload type, and the second is a full payload string
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) unsupported payload type: #{payloadType}"
    end

end
