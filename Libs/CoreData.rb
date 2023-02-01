
# encoding: UTF-8

class CoreData

    # The principal design idea of CoreData is that we refer to specific storage units by 
    # a single string and mutations of the storage unit are transparent to the holder.
    # Issuing another storage unit corresponds to a different string

    # CoreData::coreDataTypes()
    def self.payloadTypes()
        ["nyx-directory"]
    end

    # CoreData::interactivelySelectCoreDataType()
    def self.interactivelySelectCoreDataType()
        types = CoreData::coreDataTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("coredata type", types)
    end

    # CoreData::issuePayload(uuid) # payload string
    def self.issuePayload(uuid)
        # This function is called during the making of a new node (or when we are issuing a new payload of an existing node)
        # It does stuff and returns a payload string or null
        payloadType = CoreData::interactivelySelectCoreDataType()
        return nil if payloadType.nil?
        if payloadType == "nyx-directory" then
            folderpath = NyxDirectories::makeNewDirectory(uuid)
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
            return "nyx-directory:#{uuid}"
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) unsupported coredata type: #{payloadType}"
    end

end
