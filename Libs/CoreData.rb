
# encoding: UTF-8

class CoreData

    # CoreData::coreDataReferenceTypes()
    def self.coreDataReferenceTypes()
        ["nyx directory", "unique string", "just text", "url", "aion point", "Dx8Unit"]
    end

    # CoreData::interactivelySelectCoreDataReferenceType()
    def self.interactivelySelectCoreDataReferenceType()
        types = CoreData::coreDataReferenceTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("coredata reference type", types)
    end

    # CoreData::interactivelyMakeNewReferenceStringOrNull(uuid) # payload string
    def self.interactivelyMakeNewReferenceStringOrNull(uuid)
        # This function is called during the making of a new node (or when we are issuing a new payload of an existing node)
        # It does stuff and returns a payload string or null
        referencetype = CoreData::interactivelySelectCoreDataReferenceType()
        if referencetype.nil? then
            if LucilleCore::askQuestionAnswerAsBoolean("> confirm null reference string ? ") then
                return "null"
            else
                return CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
            end
        end
        if referencetype == "nyx directory" then
            folderpath = NyxDirectories::makeNewDirectory(uuid)
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
            return "nyx-directory:#{uuid}"
        end
        if referencetype == "unique string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string: ")
            return "unique-string:#{uniquestring}"
        end
        if referencetype == "just text" then
            text = CommonUtils::editTextSynchronously("")
            nhash = DatablobStore::put(text)
            return "just-text:#{nhash}"
        end
        if referencetype == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            nhash = DatablobStore::put(url)
            return "url:#{nhash}"
        end
        if referencetype == "aion point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            nhash = AionCore::commitLocationReturnHash(DatablobStoreElizabeth.new(), location)
            return "aion-point:#{nhash}" 
        end
        if referencetype == "Dx8Unit" then
            unitId = LucilleCore::askQuestionAnswerAsString("Dx8Unit Id: ")
            return "Dx8UnitId:#{unitId}"
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) unsupported core data reference type: #{referencetype}"
    end

    # CoreData::access(referenceString)
    def self.access(referenceString)

    end

    # CoreData::edit(referenceString) # new reference string
    def self.edit(referenceString)

    end
end
