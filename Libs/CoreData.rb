
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
            if LucilleCore::askQuestionAnswerAsBoolean("> confirm null reference string ? ", true) then
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
        if referenceString.nil? then
            puts "Accessing null reference string. Nothing to do."
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString == "null" then
            puts "Accessing null reference string. Nothing to do."
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("nyx-directory") then
            directoryId = referenceString.split(":")[1]
            NyxDirectories::access(directoryId)
            return
        end
        if referenceString.start_with?("unique-string") then
            uniquestring = referenceString.split(":")[1]
            puts "CoreData, accessing unique string: #{uniquestring}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("text") then
            nhash = referenceString.split(":")[1]
            puts "CoreData, accessing text: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("url") then
            nhash = referenceString.split(":")[1]
            url = DatablobStore::getOrNull(nhash)
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            return
        end
        if referenceString.start_with?("aion-point") then
            nhash = referenceString.split(":")[1]
            puts "CoreData, accessing aion point: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("Dx8UnitId") then
            unitId = referenceString.split(":")[1]
            Dx8Units::access(unitId)
            return
        end
        raise "CoreData, I do not know how to access '#{referenceString}'"
    end

    # CoreData::edit(referenceString) # new reference string
    def self.edit(referenceString)
        if referenceString == "null" then
            return CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        end
        if referenceString.start_with?("nyx-directory") then
            directoryId = referenceString.split(":")[1]
            NyxDirectories::access(directoryId)
            return
        end
        if referenceString.start_with?("unique-string") then
            uniquestring = referenceString.split(":")[1]
            puts "CoreData, editing unique string: #{uniquestring}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("text") then
            nhash = referenceString.split(":")[1]
            puts "CoreData, editing text: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("url") then
            nhash = referenceString.split(":")[1]
            puts "CoreData, editing url: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("aion-point") then
            rootnhash = referenceString.split(":")[1]

            exportLocation = "#{ENV['HOME']}/Desktop/aion-point-#{SecureRandom.hex(4)}"
            FileUtils.mkdir(exportLocation)
            AionCore::exportHashAtFolder(rootnhash, exportLocation)
            puts "Item exported at #{exportLocation} for edition"
            LucilleCore::pressEnterToContinue()

            acquireLocationInsideExportFolder = lambda {|exportLocation|
                locations = LucilleCore::locationsAtFolder(exportLocation).select{|loc| File.basename(loc)[0, 1] != "."}
                if locations.size == 0 then
                    puts "I am in the middle of a CoreData aion-point edit. I cannot see anything inside the export folder"
                    puts "Exit"
                    exit
                end
                if locations.size == 1 then
                    return locations[0]
                end
                if locations.size > 1 then
                    puts "I am in the middle of a CoreData aion-point edit. I found more than one location in the export folder."
                    puts "Exit"
                    exit
                end
            }

            location = acquireLocationInsideExportFolder.call(exportLocation)
            puts "reading: #{location}"
            rootnhash = AionCore::commitLocationReturnHash(location)

            return "aion-point:#{rootnhash}"
        end
        if referenceString.start_with?("Dx8UnitId") then
            unitId = referenceString.split(":")[1]
            Dx8Units::access(unitId)
            return
        end
        raise "CoreData, I do not know how to edit '#{referenceString}'"
    end

    # CoreData::fsck(referenceString) # error if not validation
    def self.fsck(referenceString)
        if referenceString == "null" then
            return
        end
        if referenceString.start_with?("nyx-directory") then
            directoryId = referenceString.split(":")[1]
            folderpath = NyxDirectories::directoryPath(directoryId)
            if !File.exist?(folderpath) then
                raise "CoreData fsck nyx-directory. Could not see directory: #{directoryId}"
            end
            return
        end
        if referenceString.start_with?("unique-string") then
            uniquestring = referenceString.split(":")[1]
            return
        end
        if referenceString.start_with?("text") then
            nhash = referenceString.split(":")[1]
            text = DatablobStore::getOrNull(nhash)
            if text.nil? then
                raise "CoreData fsck text. Could not find text datablob: #{nhash}"
            end
            return
        end
        if referenceString.start_with?("url") then
            nhash = referenceString.split(":")[1]
            url = DatablobStore::getOrNull(nhash)
            if url.nil? then
                raise "CoreData fsck url. Could not find url datablob: #{nhash}"
            end
            return
        end
        if referenceString.start_with?("aion-point") then
            rootnhash = referenceString.split(":")[1]
            FileSystemCheck::fsck_aion_point_rootnhash(rootnhash, true)
            return
        end
        if referenceString.start_with?("Dx8UnitId") then
            unitId = referenceString.split(":")[1]
            return
        end
        if referenceString.start_with?("file") then
            nhash = referenceString.split(":")[1]
            coordinates = DatablobStore::getOrNull(nhash)
            if coordinates.nil? then
                raise "(error: 5430ba33-0858-411c-8e9a-d8968fc58fbe) looking for file coordinates and didn't find for nhash: #{nhash}"
            end
            coordinates      = JSON.parse(coordinates) 
            dottedExtension  = coordinates["dottedExtension"]
            nhash            = coordinates["nhash"]
            parts            = coordinates["parts"]
            status = PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(dottedExtension, nhash, parts, true)
            if !status then
                puts JSON.pretty_generate(coordinates)
                raise "(error: 3e428541-805b-455e-b6a2-c400a6519aef) primitive file fsck failed"
            end
            return
        end
        raise "CoreData, I do not know how to fsck '#{referenceString}'"
    end
end
