
# encoding: UTF-8

# require_relative "../Catalyst-Common/Catalyst-Common.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/CoreData.rb"
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

CATALYST_COMMON_DATABANK_FOLDERPATH = "/Users/pascal/Galaxy/DataBank" unless defined? CATALYST_COMMON_DATABANK_FOLDERPATH
CATALYST_COMMON_CATALYST_FOLDERPATH = "#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Catalyst" unless defined? CATALYST_COMMON_CATALYST_FOLDERPATH
CATALYST_COMMON_BIN_TIMELINE_FOLDERPATH = "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/Bin-Timeline" unless defined? CATALYST_COMMON_BIN_TIMELINE_FOLDERPATH

# -----------------------------------------------------------------

class CatalystCommon

    # CatalystCommon::editTextUsingTextmate(text)
    def self.editTextUsingTextmate(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("/usr/local/bin/mate \"#{filepath}\"")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end

    # CatalystCommon::onScreenNotification(title, message)
    def self.onScreenNotification(title, message)
        title = title.gsub("'","")
        message = message.gsub("'","")
        message = message.gsub("[","|")
        message = message.gsub("]","|")
        command = "terminal-notifier -title '#{title}' -message '#{message}'"
        system(command)
    end

    # CatalystCommon::copyLocationToCatalystBin(location)
    def self.copyLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        folder1 = "#{CATALYST_COMMON_BIN_TIMELINE_FOLDERPATH}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{Time.new.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{LucilleCore::timeStringL22()}"
        FileUtils.mkdir(folder3)
        LucilleCore::copyFileSystemLocation(location, folder3)
    end

    # CatalystCommon::commitTextToCatalystBin(filename, text)
    def self.commitTextToCatalystBin(filename, text)
        folder1 = "#{CATALYST_COMMON_BIN_TIMELINE_FOLDERPATH}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{Time.new.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{LucilleCore::timeStringL22()}"
        FileUtils.mkdir(folder3)
        File.open("#{folder3}/#{filename}", "w"){|f| f.puts(text) }
    end

    # CatalystCommon::getIFCSPositionForItemCreation()
    def self.getIFCSPositionForItemCreation()
        ifcsreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Projects/ifcs-items-report`
        puts ifcsreport
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ").strip
        if position.size>0 then
            position.to_f
        else
            `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Projects/ifcs-highest-current-position`.to_f + 1
        end
    end

    # CatalystCommon::createNewCatalystStandardTargetInteractivelyOrNull()
    def self.createNewCatalystStandardTargetInteractivelyOrNull()
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

    # CatalystCommon::openCatalystStandardTarget(target)
    def self.openCatalystStandardTarget(target)
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
        raise "Catalyst Common error 160050-490261"
    end

end
