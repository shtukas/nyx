class Upload

    # Upload::linkuploadAllLocationsOfAFolderAsLinkedAionPoint(item)
    def self.linkuploadAllLocationsOfAFolderAsLinkedAionPoint(item)
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
            NxLink::issue(item["uuid"], child["uuid"])
        }
    end

    # Upload::uploadAllLocationsOfAFolderAsLinkedPrimitiveFiles(item)
    def self.uploadAllLocationsOfAFolderAsLinkedPrimitiveFiles(item)
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
            NxLink::issue(item["uuid"], child["uuid"])
        }
    end

    # Upload::interactivelyUploadToItem(item)
    def self.interactivelyUploadToItem(item)
        puts "Upload to '#{LxFunction::function("toString", item)}'".green
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["single file", "aion-points", "primitive files"])
        return if action.nil?
        if action == "single file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return if location.nil?
            child = NxDataNodes::issuePrimitiveFileFromLocationOrNull(location)
            return if child.nil?
            NxLink::issue(item["uuid"], child["uuid"])
        end
        if action == "aion-points" then
            Upload::linkuploadAllLocationsOfAFolderAsLinkedAionPoint(item)
        end
        if action == "primitive files" then
            Upload::uploadAllLocationsOfAFolderAsLinkedPrimitiveFiles(item)
        end
    end
end
