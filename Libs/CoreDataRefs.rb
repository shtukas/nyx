
# encoding: UTF-8

class CoreDataRefs

    # CoreDataRefs::coreDataReferenceTypes()
    def self.coreDataReferenceTypes()
        ["text", "url", "aion point", "unique string"]
    end

    # CoreDataRefs::interactivelySelectCoreDataReferenceType()
    def self.interactivelySelectCoreDataReferenceType()
        types = CoreDataRefs::coreDataReferenceTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("coredata reference type", types)
    end

    # CoreDataRefs::interactivelyMakeNewReferenceOrNull(orbital) # payload string
    def self.interactivelyMakeNewReferenceOrNull(orbital)
        # This function is called during the making of a new node (or when we are issuing a new payload of an existing node)
        # It does stuff and returns a payload string or null
        referencetype = CoreDataRefs::interactivelySelectCoreDataReferenceType()
        if referencetype.nil? then
            return {
                "uuid"        => SecureRandom.uuid,
                "mikuType"    => "CoreDataRef",
                "unixtime"    => Time.new.to_f,
                "description" => nil,
                "type"        => "null"
            }
        end
        if referencetype == "text" then
            text = CommonUtils::editTextSynchronously("")
            return {
                "uuid"         => SecureRandom.uuid,
                "mikuType"    => "CoreDataRef",
                "unixtime"     => Time.new.to_f,
                "description"  => nil,
                "type"         => "text",
                "uniquestring" => uniquestring
            }
        end
        if referencetype == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return {
                "uuid"        => SecureRandom.uuid,
                "mikuType"    => "CoreDataRef",
                "unixtime"    => Time.new.to_f,
                "description" => nil,
                "type"        => "url",
                "url"         => url
            }
        end
        if referencetype == "aion point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            nhash = AionCore::commitLocationReturnHash(Elizabeth.new(orbital), location)
            return {
                "uuid"        => SecureRandom.uuid,
                "mikuType"    => "CoreDataRef",
                "unixtime"    => Time.new.to_f,
                "description" => nil,
                "type"        => "aion-point",
                "nhash"       => nhash
            }
        end
        if referencetype == "unique string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
            return {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "CoreDataRef",
                "unixtime"     => Time.new.to_f,
                "description"  => nil,
                "type"         => "unique-string",
                "uniquestring" => uniquestring
            }
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) unsupported core data reference type: #{referencetype}"
    end

    # CoreDataRefs::toString(reference)
    def self.toString(reference)
        if reference.nil? then
            return "core data (#{reference["uuid"][0, 2]}): null"
        end
        if reference["type"] == "null" then
            return "core data (#{reference["uuid"][0, 2]}): null"
        end
        if reference["type"] == "text" then
            return "core data (#{reference["uuid"][0, 2]}): text"
        end
        if reference["type"] == "url" then
            return "core data (#{reference["uuid"][0, 2]}): url"
        end
        if reference["type"] == "aion-point" then
            return "core data (#{reference["uuid"][0, 2]}): aion-point"
        end
        if reference["type"] == "unique-string" then
            return "core data (#{reference["uuid"][0, 2]}): unique-string"
        end
        raise "CoreData, I do not know how to string '#{reference}'"
    end

    # CoreDataRefs::access(reference, orbital)
    def self.access(reference, orbital)
        if reference.nil? then
            puts "Accessing null reference string. Nothing to do."
            LucilleCore::pressEnterToContinue()
            return
        end
        if reference["type"] == "null" then
            puts "Accessing null reference string. Nothing to do."
            LucilleCore::pressEnterToContinue()
            return
        end
        if reference["type"] == "text" then
            text = reference["text"]
            puts "--------------------------------------------------------------"
            puts text
            puts "--------------------------------------------------------------"
            LucilleCore::pressEnterToContinue()
            return
        end
        if reference["type"] == "url" then
            url = reference["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            LucilleCore::pressEnterToContinue()
            return
        end
        if reference["type"] == "aion-point" then
            nhash = reference["nhash"]
            puts "CoreData, accessing aion point: #{nhash}"
            exportId = SecureRandom.hex(4)
            exportFoldername = "aion-point-#{exportId}"
            exportFolder = "#{Config::pathToDesktop()}/#{exportFoldername}"
            FileUtils.mkdir(exportFolder)
            AionCore::exportHashAtFolder(Elizabeth.new(orbital), nhash, exportFolder)
            LucilleCore::pressEnterToContinue()
            return
        end
        if reference["type"] == "unique-string" then
            uniquestring = reference["uniquestring"]
            puts "CoreData, accessing unique string: #{uniquestring}"
            location = Atlas::uniqueStringToLocationOrNull(uniquestring)
            if location then
                puts "location: #{location}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        raise "CoreData, I do not know how to access '#{reference}'"
    end

    # CoreDataRefs::edit(reference, orbital) # new reference
    def self.edit(reference, orbital)
        if reference.nil? then
            return CoreDataRefs::interactivelyMakeNewReferenceOrNull(orbital)
        end
        if reference["type"] == "null" then
            return CoreDataRefs::interactivelyMakeNewReferenceOrNull(orbital)
        end
        if reference["type"] == "null" then
            puts "Accessing null reference string. Making a new one."
            return CoreDataRefs::interactivelyMakeNewReferenceOrNull(orbital) 
        end
        if reference["type"] == "text" then
            text = reference["text"]
            puts "CoreData, editing text: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if reference["type"] == "url" then
            url = reference["url"]
            puts "CoreData, editing url: #{nhash}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        if reference["type"] == "aion-point" then
            rootnhash = reference["nhash"]
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
            reference["nhash"] = rootnhash
            return reference
        end
        if reference["type"] == "unique-string" then
            uniquestring = reference["uniquestring"]
            puts "CoreData, editing unique string: #{uniquestring}"
            puts "not implemented yet"
            LucilleCore::pressEnterToContinue()
            return
        end
        raise "CoreData, I do not know how to edit '#{reference}'"
    end

    # CoreDataRefs::fsckRightOrError(reference, orbital)
    def self.fsckRightOrError(reference, orbital)
        if reference.nil? then
            return
        end
        if reference["type"] == "null" then
            return
        end
        if reference["type"] == "text" then
            text = reference["text"]
            return if text
            raise "missing text at orbital #{orbital.uuid()} for reference: #{reference}"
        end
        if reference["type"] == "url" then
            url = reference["url"]
            return if url
            raise "missing url at orbital #{orbital.uuid()} for reference: #{reference}"
        end
        if reference["type"] == "aion-point" then
            rootnhash = reference["nhash"]
            operator = Elizabeth.new(orbital)
            AionFsck::structureCheckAionHashRaiseErrorIfAny(operator, rootnhash)
            return
        end
        if reference["type"] == "unique-string" then
            return
        end
        raise "CoreData, I do not know how to fsck '#{reference}'"
    end

    # CoreDataRefs::landing(note)
    def self.landing(note)
        puts "CoreDataRefs::landing not implemented yet"
        LucilleCore::pressEnterToContinue() 
    end
end
