
# encoding: UTF-8

class CoreData

    # CoreData::coreDataReferenceTypes()
    def self.coreDataReferenceTypes()
        ["nyx-directory"]
    end

    # CoreData::interactivelySelectCoreDataReferenceType()
    def self.interactivelySelectCoreDataReferenceType()
        types = CoreData::coreDataReferenceTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("coredata reference type", types)
    end

    # CoreData::referenceString(uuid) # payload string
    def self.referenceString(uuid)
        # This function is called during the making of a new node (or when we are issuing a new payload of an existing node)
        # It does stuff and returns a payload string or null
        referencetype = CoreData::interactivelySelectCoreDataReferenceType()
        return nil if referencetype.nil?
        if referencetype == "nyx-directory" then
            folderpath = NyxDirectories::makeNewDirectory(uuid)
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
            return "nyx-directory:#{uuid}"
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) unsupported core data reference type: #{referencetype}"
    end

    # CoreData::access(referenceString)
    def self.access(referenceString)

    end

    # CoreData::edit(referenceString)
    def self.edit(referenceString)

    end
end
