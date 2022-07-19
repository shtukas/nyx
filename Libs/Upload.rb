class Upload

    # Upload::linkuploadAllLocationsOfAFolderAsLinkedAionPoint(item, overrideDatetime)
    def self.linkuploadAllLocationsOfAFolderAsLinkedAionPoint(item, overrideDatetime)
        folder = LucilleCore::askQuestionAnswerAsString("folder: ")
        if !File.exists?(folder) then
            puts "The given location doesn't exist (#{folder})"
            LucilleCore::pressEnterToContinue()
            return
        end
        if !File.directory?(folder) then
            puts "The given location is not a directory (#{folder})"
            LucilleCore::pressEnterToContinue()
            return
        end
        LucilleCore::locationsAtFolder(folder).each{|location|
            puts "processing: #{location}"
            child = NxDataNodes::issueNewItemAionPointFromLocation(location)
            if overrideDatetime then
                Fx18Attributes::setAttribute2(child["uuid"], "datetime", overrideDatetime)
            end
            NxLink::issue(item["uuid"], child["uuid"])
        }
    end

    # Upload::uploadAllLocationsOfAFolderAsLinkedPrimitiveFiles(item, overrideDatetime)
    def self.uploadAllLocationsOfAFolderAsLinkedPrimitiveFiles(item, overrideDatetime)
        folder = LucilleCore::askQuestionAnswerAsString("folder: ")
        if !File.exists?(folder) then
            puts "The given location doesn't exist (#{folder})"
            LucilleCore::pressEnterToContinue()
            return
        end
        if !File.directory?(folder) then
            puts "The given location is not a directory (#{folder})"
            LucilleCore::pressEnterToContinue()
            return
        end
        LucilleCore::locationsAtFolder(folder).each{|location|
            puts "processing: #{location}"
            child = NxDataNodes::issuePrimitiveFileFromLocationOrNull(location)
            next if child.nil?
            if overrideDatetime then
                Fx18Attributes::setAttribute2(child["uuid"], "datetime", overrideDatetime)
            end
            NxLink::issue(item["uuid"], child["uuid"])
        }
    end

    # Upload::interactivelyUploadToItem(item)
    def self.interactivelyUploadToItem(item)
        puts "Upload to '#{LxFunction::function("toString", item)}'".green
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["single file", "aion-points", "primitive files"])
        return if action.nil?
        overrideDatetime = nil
        if !LucilleCore::askQuestionAnswerAsBoolean("Use current datetime ? ", true) then
            overrideDatetime = CommonUtils::interactiveDateTimeBuilder()
        end
        if action == "single file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return if location.nil?
            child = NxDataNodes::issuePrimitiveFileFromLocationOrNull(location)
            return if child.nil?
            if overrideDatetime then
                Fx18Attributes::setAttribute2(child["uuid"], "datetime", overrideDatetime)
            end
            NxLink::issue(item["uuid"], child["uuid"])
        end
        if action == "aion-points" then
            Upload::linkuploadAllLocationsOfAFolderAsLinkedAionPoint(item, overrideDatetime)
        end
        if action == "primitive files" then
            Upload::uploadAllLocationsOfAFolderAsLinkedPrimitiveFiles(item, overrideDatetime)
        end
    end
end
