
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'io/console'

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
        ifcsreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-items-report`
        puts ifcsreport
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ").strip
        if position.size>0 then
            position.to_f
        else
            `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-highest-current-position`.to_f + 1
        end
    end

end
