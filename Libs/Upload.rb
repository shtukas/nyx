class Upload

    # Upload::uploadAllLocationsOfAFolderAsChildrenAionPoints(item, overrideDatetime)
    def self.uploadAllLocationsOfAFolderAsChildrenAionPoints(item, overrideDatetime)
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
            child = Nx7::issueNewUsingLocation(location)
            if overrideDatetime then
                child["datetime"] = overrideDatetime
                PolyActions::commit(child)
            end
            Nx7::arrow(item, child)
        }
    end

    # Upload::uploadAllLocationsOfAFolderAsChildrenPrimitiveFiles(item, overrideDatetime)
    def self.uploadAllLocationsOfAFolderAsChildrenPrimitiveFiles(item, overrideDatetime)
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
            child = Nx7::issueNewUsingFile(filepath)
            if overrideDatetime then
                child["datetime"] = overrideDatetime
                PolyActions::commit(child)
            end
            Nx7::arrow(item, child)
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
            child = Nx7::issueNewUsingFile(location)
            if overrideDatetime then
                child["datetime"] = overrideDatetime
                PolyActions::commit(child)
            end
            Nx7::arrow(item, child)
        end
        if action == "aion-points" then
            Upload::uploadAllLocationsOfAFolderAsChildrenAionPoints(item, overrideDatetime)
        end
        if action == "primitive files" then
            Upload::uploadAllLocationsOfAFolderAsChildrenPrimitiveFiles(item, overrideDatetime)
        end
    end
end
