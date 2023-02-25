
# encoding: UTF-8

class CoreData

    # CoreData::coreDataReferenceTypes()
    def self.coreDataReferenceTypes()
        ["nyx directory", "unique string", "text", "url", "aion point", "Dx8Unit", "OpenCycle Directory"]
    end

    # CoreData::interactivelySelectCoreDataReferenceType()
    def self.interactivelySelectCoreDataReferenceType()
        types = CoreData::coreDataReferenceTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("coredata reference type", types)
    end

    # CoreData::interactivelyMakeNewReferenceStringOrNull(orbital) # payload string
    def self.interactivelyMakeNewReferenceStringOrNull(orbital)
        # This function is called during the making of a new node (or when we are issuing a new payload of an existing node)
        # It does stuff and returns a payload string or null
        referencetype = CoreData::interactivelySelectCoreDataReferenceType()
        if referencetype.nil? then
            return "null"
        end
        if referencetype == "nyx directory" then
            folderpath = NyxDirectories::makeNew(orbital.uuid())
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
            return "nyx-directory:#{orbital.uuid()}"
        end
        if referencetype == "unique string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
            return "unique-string:#{uniquestring}"
        end
        if referencetype == "text" then
            text = CommonUtils::editTextSynchronously("")
            nhash = orbital.put_blob(text)
            return "text:#{nhash}"
        end
        if referencetype == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            nhash = orbital.put_blob(url)
            return "url:#{nhash}"
        end
        if referencetype == "aion point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            nhash = AionCore::commitLocationReturnHash(Elizabeth.new(orbital), location)
            return "aion-point:#{nhash}" 
        end
        if referencetype == "Dx8Unit" then
            unitId = LucilleCore::askQuestionAnswerAsString("Dx8Unit Id: ")
            return "Dx8UnitId:#{unitId}"
        end
        if referencetype == "OpenCycle Directory" then
            fname = LucilleCore::askQuestionAnswerAsString("OpenCycle directory name: ")
            return "open-cycle:#{fname}"
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) unsupported core data reference type: #{referencetype}"
    end

    # CoreData::referenceStringToSuffixString(referenceString)
    def self.referenceStringToSuffixString(referenceString)
        if referenceString.nil? then
            return ""
        end
        if referenceString == "null" then
            return ""
        end
        if referenceString.start_with?("nyx-directory") then
            return " (nyx directory)"
        end
        if referenceString.start_with?("unique-string") then
            str = referenceString.split(":")[1]
            return " (unique string: #{str})"
        end
        if referenceString.start_with?("text") then
            return " (text)"
        end
        if referenceString.start_with?("url") then
            return " (url)"
        end
        if referenceString.start_with?("aion-point") then
            return " (aion point)"
        end
        if referenceString.start_with?("Dx8UnitId") then
            return " (Dx8Unit)"
        end
        if referenceString.start_with?("open-cycle") then
            return " (#{referenceString})"
        end
        raise "CoreData, I do not know how to string '#{referenceString}'"
    end

    # CoreData::access(referenceString, orbital)
    def self.access(referenceString, orbital)
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
            location = Atlas::uniqueStringToLocationOrNull(uniquestring)
            if location then
                puts "location: #{location}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if referenceString.start_with?("text") then
            nhash = referenceString.split(":")[1]
            text = orbital.get(nhash)
            puts "--------------------------------------------------------------"
            puts text
            puts "--------------------------------------------------------------"
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("url") then
            nhash = referenceString.split(":")[1]
            url = orbital.get(nhash)
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("aion-point") then
            nhash = referenceString.split(":")[1]
            puts "CoreData, accessing aion point: #{nhash}"
            exportId = SecureRandom.hex(4)
            exportFoldername = "aion-point"
            exportFolder = "#{Config::pathToDesktop()}/#{exportFoldername}"
            FileUtils.mkdir(exportFolder)
            AionCore::exportHashAtFolder(Elizabeth.new(orbital), nhash, exportFolder)
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("Dx8UnitId") then
            unitId = referenceString.split(":")[1]
            Dx8Units::access(unitId)
            return
        end
        if referenceString.start_with?("open-cycle") then
            fname = referenceString.split(":")[1]
            directoryFilepath = "#{Config::pathToGalaxy()}/OpenCycles/#{fname}"
            system("open '#{directoryFilepath}'")
            return
        end

        raise "CoreData, I do not know how to access '#{referenceString}'"
    end

    # CoreData::edit(referenceString, orbital) # new reference string
    def self.edit(referenceString, orbital)
        if referenceString == "null" then
            return CoreData::interactivelyMakeNewReferenceStringOrNull(orbital)
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
        if referenceString.start_with?("open-cycle") then
            CoreData::access(referenceString, orbital)
            return
        end
        raise "CoreData, I do not know how to edit '#{referenceString}'"
    end

    # CoreData::fsckRightOrError(referenceString, orbital)
    def self.fsckRightOrError(referenceString, orbital)
        if referenceString.nil? then
            return
        end
        if referenceString == "null" then
            return
        end
        if referenceString.start_with?("nyx-directory") then
            return
        end
        if referenceString.start_with?("unique-string") then
            return
        end
        if referenceString.start_with?("text") then
            nhash = referenceString.split(":")[1]
            text = orbital.get(nhash)
            return if text
            raise "missing text at orbital #{orbital.uuid()} for referenceString: #{referenceString}"
        end
        if referenceString.start_with?("url") then
            nhash = referenceString.split(":")[1]
            url = orbital.get(nhash)
            return if url
            raise "missing url at orbital #{orbital.uuid()} for referenceString: #{referenceString}"
        end
        if referenceString.start_with?("aion-point") then
            nhash = referenceString.split(":")[1]
            operator = Elizabeth.new(orbital)
            AionFsck::structureCheckAionHashRaiseErrorIfAny(operator, nhash)
            return
        end
        if referenceString.start_with?("Dx8UnitId") then
            return
        end
        if referenceString.start_with?("open-cycle") then
            return
        end

        raise "CoreData, I do not know how to fsck '#{referenceString}'"
    end
end
