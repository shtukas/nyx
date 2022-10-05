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
            child = NyxNodes::issueNewUsingLocation(location)
            if overrideDatetime then
                Items::setAttribute2(child["uuid"], "datetime", overrideDatetime)
            end
            NetworkEdges::relate(item["uuid"], child["uuid"])
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
        LucilleCore::locationsAtFolder(folder).each{|filepath|
            puts "processing: #{filepath}"
            child = NyxNodes::issueNewUsingFile(filepath)
            if overrideDatetime then
                Items::setAttribute2(child["uuid"], "datetime", overrideDatetime)
            end
            NetworkEdges::relate(item["uuid"], child["uuid"])
        }
    end

    # Upload::interactivelyUploadToItem(item)
    def self.interactivelyUploadToItem(item)
        puts "Upload to '#{PolyFunctions::toString(item)}'".green
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["single file", "aion-points", "primitive files"])
        return if action.nil?
        overrideDatetime = nil
        if !LucilleCore::askQuestionAnswerAsBoolean("Use current datetime ? ", true) then
            overrideDatetime = CommonUtils::interactiveDateTimeBuilder()
        end
        if action == "single file" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return if location.nil?
            return if !File.file?(location)
            child = NyxNodes::issueNewUsingFile(location)
            if overrideDatetime then
                Items::setAttribute2(child["uuid"], "datetime", overrideDatetime)
            end
            NetworkEdges::relate(item["uuid"], child["uuid"])
        end
        if action == "aion-points" then
            Upload::linkuploadAllLocationsOfAFolderAsLinkedAionPoint(item, overrideDatetime)
        end
        if action == "primitive files" then
            Upload::uploadAllLocationsOfAFolderAsLinkedPrimitiveFiles(item, overrideDatetime)
        end
    end
end
