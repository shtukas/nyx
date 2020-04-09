#!/usr/bin/ruby

# encoding: UTF-8

require 'find'

require 'json'

require 'time'

require 'colorize'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(5) #=> "eb693"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"
# LucilleCore::askQuestionAnswerAsString(question)
# LucilleCore::askQuestionAnswerAsBoolean(announce, defaultValue = nil)

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation, key)
    KeyValueStore::setFlagFalse(repositorylocation, key)
    KeyValueStore::flagIsTrue(repositorylocation, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/AtlasCore.rb"

# --------------------------------------------------------------------

$HimaliaLinesToPermanodeUUIDsMap = {}

class NyxMiscUtils

    # NyxMiscUtils::editTextUsingTextmate(text)
    def self.editTextUsingTextmate(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("/usr/local/bin/mate \"#{filepath}\"")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end

    # NyxMiscUtils::l22()
    def self.l22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NyxMiscUtils::chooseALinePecoStyle(announce: String, strs: Array[String]): String
    def self.chooseALinePecoStyle(announce, strs)
        `echo "#{strs.join("\n")}" | peco --prompt "#{announce}"`.strip
    end

    # NyxMiscUtils::cleanStringToBeFileSystemName(str)
    def self.cleanStringToBeFileSystemName(str)
        str = str.gsub(" ", "-")
        str = str.gsub("'", "-")
        str = str.gsub(":", "-")
        str = str.gsub("/", "-")
        str = str.gsub("!", "-")
        str
    end

    # NyxMiscUtils::locationsNamesInsideFolder(folderpath): Array[String]
    def self.locationsNamesInsideFolder(folderpath)
        Dir.entries(folderpath)
            .reject{|filename| [".", ".."].include?(filename) }
            .reject{|filename| filename == "Icon\r" }
            .reject{|filename| filename == ".DS_Store" }
            .sort
    end

    # NyxMiscUtils::locationPathsInsideFolder(folderpath): Array[String]
    def self.locationPathsInsideFolder(folderpath)
        NyxMiscUtils::locationsNamesInsideFolder(folderpath).map{|filename| "#{folderpath}/#{filename}" }
    end

    # NyxMiscUtils::readFileAsIndividualNonEmptyStrippedLineItems(filepath)
    def self.readFileAsIndividualNonEmptyStrippedLineItems(filepath)
        IO.read(filepath).lines.map{|line| line.strip }.select{|line| line.size > 0 }
    end

    # NyxMiscUtils::recursivelyComputedLocationTrace(location): String
    def self.recursivelyComputedLocationTrace(location)
        if File.file?(location) then
            Digest::SHA1.hexdigest("#{location}:#{File.mtime(location)}")
        else
            Digest::SHA1.hexdigest(
                ([location] + NyxMiscUtils::locationPathsInsideFolder(location).map{|l| NyxMiscUtils::recursivelyComputedLocationTrace(l) }).join("::")
            )
        end
    end

    # NyxMiscUtils::rsync(sourceFolderpath, targetFolderpath)
    def self.rsync(sourceFolderpath, targetFolderpath)
        if !File.exists?(sourceFolderpath) then
            raise "[error: 653b1b57] Impossible rsync" 
        end
        command = "rsync --xattrs --times --recursive --hard-links --delete --delete-excluded --verbose --human-readable --itemize-changes --links '#{sourceFolderpath}/' '#{targetFolderpath}'"
        system(command)
    end

    # NyxMiscUtils::uniqueNameResolutionLocationPathOrNull(uniquename)
    def self.uniqueNameResolutionLocationPathOrNull(uniquename)
        location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
        return nil if location.nil?
        location
    end

    # NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(mark)
    def self.lStoreMarkResolutionToMarkFilepathOrNull(mark)
        location = AtlasCore::uniqueStringToLocationOrNull(mark)
        return nil if location.nil?
        location
    end

    # NyxMiscUtils::isProperDateTimeIso8601(datetime)
    def self.isProperDateTimeIso8601(datetime)
        DateTime.parse(datetime).to_time.utc.iso8601 == datetime
    end

    # NyxMiscUtils::publishIndex2PermanodesAsOneObject()
    def self.publishIndex2PermanodesAsOneObject()
        targetFilepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nyx/permanodes.json"
        File.open(targetFilepath, "w"){|f| f.puts(JSON.pretty_generate(NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir()).to_a))}
    end

    # NyxMiscUtils::formatTimeline(timeline)
    def self.formatTimeline(timeline)
        timeline.split(" ").map{|word| word.downcase.capitalize }.join(" ")
    end

    # NyxMiscUtils::selectOneOrMoreFilesOnTheDesktopByLocation()
    def self.selectOneOrMoreFilesOnTheDesktopByLocation() # Array[String]
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1]!='.' }
                            .sort
        puts "Select files:"
        locations, _ = LucilleCore::selectZeroOrMore("files:", [], desktopLocations, lambda{ |location| File.basename(location) })
        locations
    end

    # NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
    def self.commitPermanodeToDiskWithMaintenance(permanode)
        NyxPermanodeOperator::commitPermanodeToDisk(Nyx::pathToYmir(), permanode)
        NyxMiscUtils::publishIndex2PermanodesAsOneObject()
    end

    # NyxMiscUtils::levenshteinDistance(s, t)
    def self.levenshteinDistance(s, t)
      # https://stackoverflow.com/questions/16323571/measure-the-distance-between-two-strings-with-ruby
      m = s.length
      n = t.length
      return m if n == 0
      return n if m == 0
      d = Array.new(m+1) {Array.new(n+1)}

      (0..m).each {|i| d[i][0] = i}
      (0..n).each {|j| d[0][j] = j}
      (1..n).each do |j|
        (1..m).each do |i|
          d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                      d[i-1][j-1]       # no operation required
                    else
                      [ d[i-1][j]+1,    # deletion
                        d[i][j-1]+1,    # insertion
                        d[i-1][j-1]+1,  # substitution
                      ].min
                    end
        end
      end
      d[m][n]
    end

    # NyxMiscUtils::nyxStringDistance(str1, str2)
    def self.nyxStringDistance(str1, str2)
        # This metric takes values between 0 and 1
        return 1 if str1.size == 0
        return 1 if str2.size == 0
        NyxMiscUtils::levenshteinDistance(str1, str2).to_f/[str1.size, str2.size].max
    end

end
