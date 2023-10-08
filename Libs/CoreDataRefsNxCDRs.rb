# encoding: UTF-8

class CoreDataRefsNxCDRs

    # CoreDataRefsNxCDRs::coreDataReferenceTypes()
    def self.coreDataReferenceTypes()
        ["text", "url", "aion point", "fs beacon", "unique string"]
    end

    # CoreDataRefsNxCDRs::interactivelySelectCoreDataReferenceType()
    def self.interactivelySelectCoreDataReferenceType()
        types = CoreDataRefsNxCDRs::coreDataReferenceTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("coredata reference type", types)
    end

    # CoreDataRefsNxCDRs::interactivelyMakeNewReferenceOrNull(uuid) # NxCoreDataRef
    def self.interactivelyMakeNewReferenceOrNull(uuid)
        referencetype = CoreDataRefsNxCDRs::interactivelySelectCoreDataReferenceType()
        if referencetype.nil? then
            return {
                "uuid"        => SecureRandom.uuid,
                "mikuType"    => "NxCoreDataRef",
                "unixtime"    => Time.new.to_f,
                "description" => nil,
                "type"        => "null"
            }
        end
        if referencetype == "text" then
            description = LucilleCore::askQuestionAnswerAsString("description (not the text) (can be left empty): ")
            description = description.size > 0 ? description : nil
            text = CommonUtils::editTextSynchronously("")
            return {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "NxCoreDataRef",
                "unixtime"     => Time.new.to_f,
                "description"  => description,
                "type"         => "text",
                "text"         => text
            }
        end
        if referencetype == "url" then
            description = LucilleCore::askQuestionAnswerAsString("description (can be left empty): ")
            description = description.size > 0 ? description : nil
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return {
                "uuid"        => SecureRandom.uuid,
                "mikuType"    => "NxCoreDataRef",
                "unixtime"    => Time.new.to_f,
                "description" => description,
                "type"        => "url",
                "url"         => url
            }
        end
        if referencetype == "aion point" then
            description = LucilleCore::askQuestionAnswerAsString("description (can be left empty): ")
            description = description.size > 0 ? description : nil
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            nhash = AionCore::commitLocationReturnHash(C3xElizabeth.new(uuid), location)
            return {
                "uuid"        => SecureRandom.uuid,
                "mikuType"    => "NxCoreDataRef",
                "unixtime"    => Time.new.to_f,
                "description" => description,
                "type"        => "aion-point",
                "nhash"       => nhash
            }
        end
        if referencetype == "fs beacon" then
            description = LucilleCore::askQuestionAnswerAsString("description (can be left empty): ")
            description = description.size > 0 ? description : nil
            beaconId = SecureRandom.hex
            beacon = {
                "beaconId" => beaconId
            }
            filename = "#{CommonUtils::sanitiseStringForFilenaming(description)}.nyx.fs-beacon"
            filepath = "#{Config::userHomeDirectory()}/Desktop/#{filename}"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(beacon)) }
            puts "I have put the file on the Desktop. Move it and"
            LucilleCore::pressEnterToContinue()
            return {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "NxCoreDataRef",
                "unixtime"     => Time.new.to_f,
                "description"  => description,
                "type"         => "fs-beacon",
                "beaconId"     => beaconId
            }
        end
        if referencetype == "unique string" then
            description = LucilleCore::askQuestionAnswerAsString("description (can be left empty): ")
            description = description.size > 0 ? description : nil
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
            return {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "NxCoreDataRef",
                "unixtime"     => Time.new.to_f,
                "description"  => description,
                "type"         => "unique-string",
                "uniquestring" => uniquestring
            }
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) unsupported core data reference type: #{referencetype}"
    end

    # CoreDataRefsNxCDRs::toString(reference)
    def self.toString(reference)
        return reference["description"] if reference["description"]
        if reference.nil? then
            return "(core data #{reference["uuid"][0, 2]}, null)"
        end
        if reference["type"] == "null" then
            return "(core data #{reference["uuid"][0, 2]}, null)"
        end
        if reference["type"] == "text" then
            return "(core data #{reference["uuid"][0, 2]}, text)"
        end
        if reference["type"] == "url" then
            return "(core data #{reference["uuid"][0, 2]}, text)"
        end
        if reference["type"] == "aion-point" then
            return "(core data #{reference["uuid"][0, 2]}, aion-point)"
        end
        if reference["type"] == "fs-beacon" then
            return "(core data #{reference["uuid"][0, 2]}, fs-beacon)"
        end
        if reference["type"] == "unique-string" then
            return "(core data #{reference["uuid"][0, 2]}, unique-string)"
        end
        raise "CoreData, I do not know how to string '#{reference}'"
    end

    # CoreDataRefsNxCDRs::access(uuid, reference)
    def self.access(uuid, reference)
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
            exportFolder = "#{Config::userHomeDirectory()}/Desktop/#{exportFoldername}"
            FileUtils.mkdir(exportFolder)
            AionCore::exportHashAtFolder(C3xElizabeth.new(uuid), nhash, exportFolder)
            LucilleCore::pressEnterToContinue()
            return
        end
        if reference["type"] == "fs-beacon" then
            beaconId = reference["beaconId"]
            filepath = Galaxy::fsBeaconToFilepathOrNull(beaconId)
            if filepath.nil? then
                puts "I could not locate beacon with Id: #{beaconId}"
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "beacon location: #{filepath}"
            if LucilleCore::askQuestionAnswerAsBoolean("open folder: #{File.dirname(filepath)} ? ", true) then
                system("open '#{File.dirname(filepath)}'")
            end
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

    # CoreDataRefsNxCDRs::program(uuid, reference)
    def self.program(uuid, reference)
        puts "At the moment, program is just access"
        LucilleCore::pressEnterToContinue()
        CoreDataRefsNxCDRs::access(uuid, reference)
    end
end
