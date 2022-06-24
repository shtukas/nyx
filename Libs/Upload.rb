class Upload

    # Upload::uploadAllLocationsOfAFolderAsAionPointChildren(item)
    def self.uploadAllLocationsOfAFolderAsAionPointChildren(item)
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

    # Upload::uploadAllLocationsOfAFolderAsAionPrimitiveFilesChildren(item)
    def self.uploadAllLocationsOfAFolderAsAionPrimitiveFilesChildren(item)
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
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["aion-points children", "files children"])
        return if action.nil?
        if action == "aion-points children" then
            Upload::uploadAllLocationsOfAFolderAsAionPointChildren(item)
        end
        if action == "files children" then
            Upload::uploadAllLocationsOfAFolderAsAionPrimitiveFilesChildren(item)
        end
    end
end
