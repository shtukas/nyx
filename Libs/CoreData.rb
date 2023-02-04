
# encoding: UTF-8

class CoreData

    # CoreData::coreDataReferenceTypes()
    def self.coreDataReferenceTypes()
        ["nyx directory", "unique string", "text", "url", "aion point", "Dx8Unit"]
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
            folderpath = NyxDirectories::makeNew(uuid)
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
            return "nyx-directory:#{uuid}"
        end
        if referencetype == "unique string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string: ")
            return "unique-string:#{uniquestring}"
        end
        if referencetype == "text" then
            text = CommonUtils::editTextSynchronously("")
            nhash = DatablobStore::put(text)
            return "text:#{nhash}"
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
        if str == "null" then
            puts "Accessing null reference string. Nothing to do."
            LucilleCore::pressEnterToContinue()
            return
        end
        if str.start_with?("nyx-directory") then
            directoryId = str.split(":")[1]
            NyxDirectories::access(directoryId)
            return
        end
        if str.start_with?("unique-string") then
            uniquestring = str.split(":")[1]
            puts "CoreData, accessing unique string: #{uniquestring}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if str.start_with?("text") then
            nhash = str.split(":")[1]
            puts "CoreData, accessing text: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if str.start_with?("url") then
            nhash = str.split(":")[1]
            puts "CoreData, accessing url: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if str.start_with?("aion-point") then
            nhash = str.split(":")[1]
            puts "CoreData, accessing aion point: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if str.start_with?("Dx8UnitId") then
            unitId = str.split(":")[1]
            Dx8Units::access(unitId)
            return
        end
    end

    # CoreData::edit(referenceString) # new reference string
    def self.edit(referenceString)
        if str == "null" then
            return CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        end
        if str.start_with?("nyx-directory") then
            directoryId = str.split(":")[1]
            NyxDirectories::access(directoryId)
            return
        end
        if str.start_with?("unique-string") then
            uniquestring = str.split(":")[1]
            puts "CoreData, editing unique string: #{uniquestring}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if str.start_with?("text") then
            nhash = str.split(":")[1]
            puts "CoreData, editing text: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if str.start_with?("url") then
            nhash = str.split(":")[1]
            puts "CoreData, editing url: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if str.start_with?("aion-point") then
            nhash = str.split(":")[1]
            puts "CoreData, editing aion point: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if str.start_with?("Dx8UnitId") then
            unitId = str.split(":")[1]
            Dx8Units::access(unitId)
            return
        end
    end

    # CoreData::fsck() # error if not validation
    def self.fsck()
        if str == "null" then
            return
        end
        if str.start_with?("nyx-directory") then
            directoryId = str.split(":")[1]
            folderpath = NyxDirectories::directoryPath(directoryId)
            if !File.exist?(folderpath) then
                raise "CoreData fsck nyx-directory. Could not see directory: #{directoryId}"
            end
            return
        end
        if str.start_with?("unique-string") then
            uniquestring = str.split(":")[1]
            return
        end
        if str.start_with?("text") then
            nhash = str.split(":")[1]
            text = DatablobStore::getOrNull(nhash)
            if text.nil? then
                raise "CoreData fsck text. Could not find text datablob: #{nhash}"
            end
            return
        end
        if str.start_with?("url") then
            nhash = str.split(":")[1]
            url = DatablobStore::getOrNull(nhash)
            if url.nil? then
                raise "CoreData fsck url. Could not find url datablob: #{nhash}"
            end
            return
        end
        if str.start_with?("aion-point") then
            rootnhash = str.split(":")[1]
            FileSystemCheck::fsck_aion_point_rootnhash(rootnhash, true)
            return
        end
        if str.start_with?("Dx8UnitId") then
            unitId = str.split(":")[1]
            return
        end
    end
end
