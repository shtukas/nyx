
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTarget.rb"
=begin 
    CatalystStandardTarget::makeNewTargetInteractivelyOrNull()
    CatalystStandardTarget::targetToString(target)
    CatalystStandardTarget::openTarget(target)
=end

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CoreData.rb"
=begin

    CoreDataFile::copyFileToRepository(filepath)
    CoreDataFile::filenameToFilepath(filename)
    CoreDataFile::filenameIsCurrent(filename)
    CoreDataFile::openOrCopyToDesktop(filename)
    CoreDataFile::deleteFile(filename)

    CoreDataDirectory::copyFolderToRepository(folderpath)
    CoreDataDirectory::foldernameToFolderpath(foldername)
    CoreDataDirectory::openFolder(foldername)
    CoreDataDirectory::deleteFolder(foldername)

=end

# -----------------------------------------------------------------

class CatalystStandardTarget

    # CatalystStandardTarget::makeNewTargetInteractivelyOrNull()
    def self.makeNewTargetInteractivelyOrNull()
        types = ["line", "file", "url", "folder"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return {
                "type" => "line",
                "line" => line
            }
        end
        nil
    end

    # CatalystStandardTarget::targetToString(target)
    def self.targetToString(target)
        if target["type"] == "line" then
            return target["line"]
        end
        if target["type"] == "file" then
            return "CoreData file: #{target["filename"]}"
        end
        if target["type"] == "url" then
            return target["url"]
        end
        if target["type"] == "folder" then
            return "CoreData folder: #{target["foldername"]}"
        end
        raise "Catalyst Standard Target error 3c7968e4"
    end

    # CatalystStandardTarget::openTarget(target)
    def self.openTarget(target)
        if target["type"] == "line" then
            puts target["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if target["type"] == "file" then
            CoreDataFile::openOrCopyToDesktop(target["filename"])
            return
        end
        if target["type"] == "url" then
            system("open '#{target["url"]}'")
            return
        end
        if target["type"] == "folder" then
            CoreDataDirectory::openFolder(target["foldername"])
            return
        end
        raise "Catalyst Standard Target error 160050-490261"
    end
end
