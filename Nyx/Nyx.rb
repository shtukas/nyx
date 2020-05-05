
# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'colorize'
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'time'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'find'
require 'thread'

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Ymir2Estate.rb"
=begin
    Ymir2Estate::makeNewYmirLocationForBasename(pathToYmir, basename)
        # If base name is meant to be the name of a folder then folder itself 
        # still need to be created. Only the parent is created.
    Ymir2Estate::locationBasenameToYmirLocationOrNull(pathToYmir, basename)
    Ymir2Estate::ymirLocationEnumerator(pathToYmir)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/AtlasCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Aether.rb"
=begin
    AetherGenesys::makeNewPoint(filepath)
    AetherKVStore::set(filepath, key, value)
    AetherKVStore::getOrNull(filepath, key)
    AetherKVStore::keys(filepath)
    AetherKVStore::destroy(filepath, key)
    AetherAionOperations::importLocationAgainstReference(filepath, xreference, location)
    AetherAionOperations::exportReferenceAtFolder(filepath, xreference, targetReconstructionFolderpath)
=end

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

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# --------------------------------------------------------------------

class NyxEstate
    # NyxEstate::uuid2aetherfilepath(uuid)
    def self.uuid2aetherfilepath(uuid)
        "/Users/pascal/Galaxy/Nyx/Points/#{uuid}.nyxpoint"
    end
end

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

    # NyxMiscUtils::selectOneFilepathOnTheDesktopOrNull()
    def self.selectOneFilepathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("location", desktopLocations, lambda{ |location| File.basename(location) })
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

class NyxOps

    # ------------------------------------------
    # Aether Ops

    # NyxOps::setCreationTimestamp(uuid, creationTimestamp)
    def self.setCreationTimestamp(uuid, creationTimestamp)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "creationTimestamp", creationTimestamp)
    end

    # NyxOps::getCreationTimestamp(uuid)
    def self.getCreationTimestamp(uuid)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        AetherKVStore::getOrNull(aetherfilepath, "creationTimestamp").to_f
    end

    # NyxOps::setReferenceDateTime(uuid, referenceDateTime)
    def self.setReferenceDateTime(uuid, referenceDateTime)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "referenceDateTime", referenceDateTime)
    end

    # NyxOps::getReferenceDateTime(uuid)
    def self.getReferenceDateTime(uuid)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        AetherKVStore::getOrNull(aetherfilepath, "referenceDateTime")
    end

    # NyxOps::setDescription(uuid, description)
    def self.setDescription(uuid, description)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "description", description)
    end

    # NyxOps::getDescription(uuid)
    def self.getDescription(uuid)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        AetherKVStore::getOrNull(aetherfilepath, "description")
    end

    # NyxOps::setTargets(uuid, targets)
    def self.setTargets(uuid, targets)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "targets", JSON.generate(targets))
    end

    # NyxOps::getTargets(uuid)
    def self.getTargets(uuid)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        targets = AetherKVStore::getOrNull(aetherfilepath, "targets")
        raise "Error 6d0d3ca1" if targets.nil?
        JSON.parse(targets)
    end

    # NyxOps::setTags(uuid, tags)
    def self.setTags(uuid, tags)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "tags", JSON.generate(tags))
    end

    # NyxOps::getTags(uuid)
    def self.getTags(uuid)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        tags = AetherKVStore::getOrNull(aetherfilepath, "tags")
        raise "Error 448111f8" if tags.nil?
        JSON.parse(tags)
    end

    # NyxOps::setStreams(uuid, streams)
    def self.setStreams(uuid, streams)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "streams", JSON.generate(streams))
    end

    # NyxOps::getStreams(uuid)
    def self.getStreams(uuid)
        aetherfilepath = NyxEstate::uuid2aetherfilepath(uuid)
        streams = AetherKVStore::getOrNull(aetherfilepath, "streams")
        raise "Error 18de3f96" if streams.nil?
        JSON.parse(streams)
    end

    # ------------------------------------------------------------------
    # To Strings

    # NyxOps::nyxTargetToString(target)
    def self.nyxTargetToString(target)
        if target["type"] == "url-EFB8D55B" then
            return "url       : #{target["url"]}"
        end
        if target["type"] == "file-3C93365A" then
            return "file      : #{target["filename"]}"
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return "uniquename: #{target["name"]}"
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            return "mark      : #{target["mark"]}"
        end
        if target["type"] == "perma-dir-11859659" then
            return "PermaDir  : #{target["uuid"]}"
        end
        raise "[error: f84bb73d]"
    end

    # NyxOps::printNyxDetails(uuid)
    def self.printNyxDetails(uuid)
        puts "Permanode:"
        puts "    uuid: #{uuid}"
        puts "    description: #{NyxOps::getDescription(uuid).green}"
        puts "    datetime: #{NyxOps::getReferenceDateTime(uuid)}"
        puts "    targets:"
        NyxOps::getTargets(uuid)
            .each{|nyxPointTarget|
                puts "        #{NyxOps::nyxTargetToString(nyxPointTarget)}"
            }
        if NyxOps::getTags(uuid).empty? then
            puts "    tags: (empty set)".green
        else
            puts "    tags"
            NyxOps::getTags(uuid).each{|item|
                puts "        #{item}".green
            }
        end
        if NyxOps::getStreams(uuid).empty? then
            puts "    streams: (empty set)".green
        else
            puts "    streams"
            NyxOps::getStreams(uuid).each{|item|
                puts "        #{item}".green
            }
        end
    end

    # ------------------------------------------
    # Opening

    # NyxOps::fileCanBeSafelyOpen(filename)
    def self.fileCanBeSafelyOpen(filename)
        true # TODO
    end

    # NyxOps::openNyxTarget(target)
    def self.openNyxTarget(target)
        if target["type"] == "url-EFB8D55B" then
            url = target["url"]
            system("open '#{url}'")
            return
        end
        if target["type"] == "file-3C93365A" then
            filename = target["filename"]
            CoreDataFile::openOrCopyToDesktop(filename)
            return
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            location = NyxMiscUtils::uniqueNameResolutionLocationPathOrNull(uniquename)
            if location then
                puts "opening: #{location}"
                system("open '#{location}'")
            else
                puts "I could not determine the location of unique name: #{uniquename}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            location = NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(target["mark"])
            if location then
                puts "opening: #{File.dirname(location)}"
                system("open '#{File.dirname(location)}'")
            else
                puts "I could not determine the location of mark: #{target["mark"]}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if target["type"] == "perma-dir-11859659" then
            CoreDataDirectory::openFolder(target["foldername"])
            return
        end
        raise "[error: 15c46fdd]"
    end

    # NyxOps::optimisticOpen(nyxuuid)
    def self.optimisticOpen(nyxuuid)
        NyxOps::printNyxDetails(nyxuuid)
        puts "    -> Opening..."
        if NyxOps::getTargets(nyxuuid).size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find target for this nyx point. Dive? ") then
                NyxUserInterface::nyxPointDive(nyxuuid)
            end
            return
        end
        target = nil
        if NyxOps::getTargets(nyxuuid).size == 1 then
            target = NyxOps::getTargets(nyxuuid).first
        else
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target:", NyxOps::getTargets(nyxuuid), lambda{|target| NyxOps::nyxTargetToString(target) })
        end
        puts JSON.pretty_generate(target)
        NyxOps::openNyxTarget(target)
    end

    # ------------------------------------------
    # IO Ops

    # NyxOps::destroyNyxPoint(nyxuuid)
    def self.destroyNyxPoint(nyxuuid)
        filepath = NyxEstate::uuid2aetherfilepath(nyxuuid)
        puts filepath
        return if !File.exists?(filepath)
        CatalystCommon::copyLocationToCatalystBin(filepath)
        FileUtils.rm(filepath)
    end

    # NyxOps::nyxuuids()
    def self.nyxuuids()
        Dir.entries("/Users/pascal/Galaxy/Nyx/Points")
            .select{|filename| filename[-9, 9] == ".nyxpoint" } # .nyxpoint
            .map{|filename| filename[0, filename.size-9] }
            .sort
    end

    # ------------------------------------------------------------------
    # Data Queries and Data Manipulations

    # NyxOps::selectNyxUUIDOrNull(uuids)
    def self.selectNyxPointOrNull(uuids)
        descriptionXp = lambda { |uuid|
            "#{NyxOps::getDescription(uuid)} (#{uuid[0,4]})"
        }
        descriptionsxp = uuids.map{|uuid| descriptionXp.call(uuid) }
        selectedDescriptionxp = NyxMiscUtils::chooseALinePecoStyle("select nyx point (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        uuid = uuids.select{|uuid| descriptionXp.call(uuid) == selectedDescriptionxp }.first
        return nil if uuid.nil?
        uuid
    end

    # NyxOps::getNyxUUIDsCarryingThisDirectoryMark(mark)
    def self.getNyxUUIDsCarryingThisDirectoryMark(mark)
        NyxOps::nyxuuids()
            .select{|uuid|
                NyxOps::getTargets(uuid).any?{|target| target["type"] == "lstore-directory-mark-BEE670D0" and target["mark"] == mark }
            }
    end

    # NyxOps::tags()
    def self.tags()
        NyxOps::nyxuuids()
            .map{|uuid| NyxOps::getTags(uuid)}
            .flatten
            .uniq
            .sort
    end

    # NyxOps::streams()
    def self.streams()
        NyxOps::nyxuuids()
            .map{|uuid| NyxOps::getStreams(uuid) }
            .flatten
            .uniq
            .sort
    end

    # NyxOps::nyxPointCarriesTag(uuid, tag)
    def self.nyxPointCarriesTag(uuid, tag)
        NyxOps::getTags(uuid).map{|t| t.downcase }.include?(tag.downcase)
    end

    # ------------------------------------------------------------------
    # Interactive Makers

    # NyxOps::makeNyxTargetFileInteractiveOrNull()
    def self.makeNyxTargetFileInteractiveOrNull()
        filepath1 = NyxMiscUtils::selectOneFilepathOnTheDesktopOrNull()
        return nil if filepath1.nil?
        filename1 = File.basename(filepath1)
        filename2 = "#{NyxMiscUtils::l22()}-#{filename1}"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        FileUtils.mv(filepath1, filepath2)
        CoreDataFile::copyFileToRepository(filepath2)
        return {
            "uuid"     => SecureRandom.uuid,
            "type"     => "file-3C93365A",
            "filename" => filename2
        }
    end

    # NyxOps::makeNyxTargetLStoreDirectoryMarkInteractiveOrNull()
    def self.makeNyxTargetLStoreDirectoryMarkInteractiveOrNull()
        options = ["mark file already exists", "mark file should be created"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return nil if option.nil?
        if option == "mark file already exists" then
            mark = LucilleCore::askQuestionAnswerAsString("mark: ")
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "lstore-directory-mark-BEE670D0",
                "mark" => mark
            }
        end
        if option == "mark file should be created" then
            mark = nil
            loop {
                targetFolderLocation = LucilleCore::askQuestionAnswerAsString("Location to the target folder: ")
                if !File.exists?(targetFolderLocation) then
                    puts "I can't see location '#{targetFolderLocation}'"
                    puts "Let's try that again..."
                    next
                end
                mark = SecureRandom.uuid
                markFilepath = "#{targetFolderLocation}/Nyx-Directory-Mark.txt"
                File.open(markFilepath, "w"){|f| f.write(mark) }
                break
            }
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "lstore-directory-mark-BEE670D0",
                "mark" => mark
            }
        end
    end

    # NyxOps::makeNyxTargetInteractiveOrNull(type)
    # type = nil | "url-EFB8D55B" | "file-3C93365A" | "unique-name-C2BF46D6" | "lstore-directory-mark-BEE670D0" | "perma-dir-11859659"
    def self.makeNyxTargetInteractiveOrNull(type)
        nyxPointTargetType =
            if type.nil? then
                LucilleCore::selectEntityFromListOfEntitiesOrNull("type", [
                    "url-EFB8D55B",
                    "unique-name-C2BF46D6",
                    "file-3C93365A",
                    "lstore-directory-mark-BEE670D0",
                    "perma-dir-11859659"]
                )
            else
                type
            end
        return nil if nyxPointTargetType.nil?
        if nyxPointTargetType == "url-EFB8D55B" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url"  => LucilleCore::askQuestionAnswerAsString("url: ").strip
            }
        end
        if nyxPointTargetType == "file-3C93365A" then
            return NyxOps::makeNyxTargetFileInteractiveOrNull()
        end
        if nyxPointTargetType == "unique-name-C2BF46D6" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => LucilleCore::askQuestionAnswerAsString("uniquename: ").strip
            }
        end
        if nyxPointTargetType == "lstore-directory-mark-BEE670D0" then
            return NyxOps::makeNyxTargetLStoreDirectoryMarkInteractiveOrNull()
        end
        if nyxPointTargetType == "perma-dir-11859659" then
            desktopLocationnames = Dir.entries("/Users/pascal/Desktop")
                                    .reject{|filename| filename[0, 1] == '.' }
                                    .reject{|filename| ["pascal.png", "Lucille-Inbox", "Lucille.txt"].include?(filename) }
            selecteddesktopLocationnames, _ = LucilleCore::selectZeroOrMore("file", [], desktopLocationnames)
            return nil if selecteddesktopLocationnames.empty?
            foldername2 = NyxMiscUtils::l22()
            folderpath2 = CoreDataDirectory::foldernameToFolderpath(foldername2)
            FileUtils.mkdir(folderpath2)
            selecteddesktopLocations = selecteddesktopLocationnames.map{|filename| "/Users/pascal/Desktop/#{filename}" }
            selecteddesktopLocations.each{|desktoplocation|
                puts "Migrating '#{desktoplocation}' to '#{folderpath2}'"
                LucilleCore::copyFileSystemLocation(desktoplocation, folderpath2)
                LucilleCore::removeFileSystemLocation(desktoplocation)
            }
            return {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
        end
        nil
    end

    # NyxOps::makeOnePermanodeTagInteractiveOrNull()
    def self.makeOnePermanodeTagInteractiveOrNull()
        LucilleCore::askQuestionAnswerAsString("tag: ")
    end

    # NyxOps::makePermanodeTagsInteractive()
    def self.makePermanodeTagsInteractive()
        tags = []
        loop {
            puts "Making tag"
            LucilleCore::pressEnterToContinue()
            tag = NyxOps::makeOnePermanodeTagInteractiveOrNull()
            break if tag.nil?
            tags << tag
        }
        tags
    end

    # NyxOps::makeOnePermanodeStreamInteractiveOrNull()
    def self.makeOnePermanodeStreamInteractiveOrNull()
        LucilleCore::askQuestionAnswerAsString("stream: ")
    end

    # NyxOps::makePermanodeStreamsInteractive()
    def self.makePermanodeStreamsInteractive()
        streams = []
        loop {
            stream = NyxOps::makeOnePermanodeStreamInteractiveOrNull()
            break if stream.nil?
            streams << stream
        }
        streams
    end

    # NyxOps::makePermanode2Interactive(description, nyxPointTarget)
    def self.makePermanode2Interactive(description, nyxPointTarget)
        uuid = SecureRandom.uuid
        tags = NyxOps::makePermanodeTagsInteractive()
        streams = NyxOps::makePermanodeStreamsInteractive()
        filepath = NyxEstate::uuid2aetherfilepath(uuid)
        AetherGenesys::makeNewPoint(filepath)
        NyxOps::setCreationTimestamp(uuid, Time.new.to_f)
        NyxOps::setReferenceDateTime(uuid, Time.now.utc.iso8601)
        NyxOps::setDescription(uuid, description)
        NyxOps::setTargets(uuid, [ nyxPointTarget ])
        NyxOps::setTags(uuid, tags)
        NyxOps::setStreams(uuid, streams)
    end

    # NyxOps::makePermanode1Interactive()
    def self.makePermanode1Interactive()
        operations = [
            "url",
            "uniquename",
            "file (from desktop)",
            "lstore-directory-mark",
            "Desktop files inside permadir"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)

        if operation == "url" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            nyxPointTarget = {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url" => url
            }
            NyxOps::makePermanode2Interactive(description, nyxPointTarget)
        end

        if operation == "uniquename" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            nyxPointTarget = {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => uniquename
            }
            NyxOps::makePermanode2Interactive(description, nyxPointTarget)
        end

        if operation == "file (from desktop)" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            nyxPointTarget = NyxOps::makeNyxTargetFileInteractiveOrNull()
            return if nyxPointTarget.nil?
            NyxOps::makePermanode2Interactive(description, nyxPointTarget)
        end

        if operation == "lstore-directory-mark" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            nyxPointTarget = NyxOps::makeNyxTargetLStoreDirectoryMarkInteractiveOrNull()
            return if nyxPointTarget.nil?
            NyxOps::makePermanode2Interactive(description, nyxPointTarget)
        end

        if operation == "Desktop files inside permadir" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            locations = NyxMiscUtils::selectOneOrMoreFilesOnTheDesktopByLocation()

            foldername2 = NyxMiscUtils::l22()
            folderpath2 = CoreDataDirectory::foldernameToFolderpath(foldername2)
            FileUtils.mkdir(folderpath2)

            nyxPointTarget = {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
            NyxOps::makePermanode2Interactive(description, nyxPointTarget)

            locations.each{|location|
                puts "Copying '#{location}'"
                LucilleCore::copyFileSystemLocation(location, folderpath2)
            }
            locations.each{|location|
                LucilleCore::removeFileSystemLocation(location)
            }
            system("open '#{folderpath2}'")
        end
    end

    # ------------------------------------------------------------------
    # Destroy

    # NyxOps::destroyNyxTargetAttempt(target)
    def self.destroyNyxTargetAttempt(target)
        if target["type"] == "url-EFB8D55B" then
            url = target["url"]
            return
        end
        if target["type"] == "file-3C93365A" then
            filename = target["filename"]
            CoreDataFile::deleteFile(filename)
            return
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            return
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            location = NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(target["mark"])
            return if location.nil?
            if NyxOps::getNyxUUIDsCarryingThisDirectoryMark(target["mark"]).size == 1 then
                puts "destroying mark file: #{location}"
                LucilleCore::removeFileSystemLocation(location)
            end
            return
        end
        if target["type"] == "perma-dir-11859659" then
            CoreDataDirectory::deleteFolder(target["foldername"])
            return
        end
        raise "[error: 15c46fdd]"
    end

    # NyxOps::destroyNyxPointAttempt(uuid)
    def self.destroyNyxPointAttempt(uuid)
        NyxOps::getTargets(uuid).all?{|target| NyxOps::destroyNyxTargetAttempt(target) }
        NyxOps::destroyNyxPoint(uuid)
    end

    # NyxOps::destroyNyxPointContentsAndPermanode(uuid)
    def self.destroyNyxPointContentsAndPermanode(uuid)
        NyxOps::destroyNyxPointAttempt(uuid)
    end
end

class NyxSearch

    # NyxSearch::searchPatternToTags(searchPattern)
    def self.searchPatternToTags(searchPattern)
        NyxOps::tags()
            .select{|tag| tag.downcase.include?(searchPattern.downcase) }
    end
    # NyxSearch::searchPatternToStreams(searchPattern)
    def self.searchPatternToStreams(searchPattern)
        NyxOps::streams()
            .select{|stream| stream.downcase.include?(searchPattern.downcase) }
    end

    # NyxSearch::searchPatternToNyxUUIDs(searchPattern)
    def self.searchPatternToNyxUUIDs(searchPattern)
        NyxOps::nyxuuids()
            .select{|uuid| NyxOps::getDescription(uuid).downcase.include?(searchPattern.downcase) }
    end

    # NyxSearch::searchPatternToNyxPointsDescriptions(searchPattern)
    def self.searchPatternToNyxPointsDescriptions(searchPattern)
        NyxSearch::searchPatternToNyxUUIDs(searchPattern)
            .map{|uuid| NyxOps::getDescription(uuid) }
            .uniq
            .sort
    end

    # NyxSearch::nextGenGetSearchFragmentOrNull()
    def self.nextGenGetSearchFragmentOrNull() # () -> String
        LucilleCore::askQuestionAnswerAsString("search fragment: ")
    end

    # NyxSearch::nextGenSearchFragmentToGlobalSearchStructure(fragment)
    def self.nextGenSearchFragmentToGlobalSearchStructure(fragment)
        objs1 = NyxSearch::searchPatternToNyxUUIDs(fragment)
                    .map{|uuid| 
                        {
                            "type" => "nyxpoint",
                            "uuid" => uuid
                        }
                    }
        objs2 = NyxSearch::searchPatternToTags(fragment)
                    .map{|tag|
                        {
                            "type" => "tag",
                            "tag" => tag
                        }
                    }
        objs1 + objs2
    end

    # NyxSearch::globalSearchStructureDive(globalss)
    def self.globalSearchStructureDive(globalss)
        loop {
            system("clear")
            globalssObjectToMenuItemOrNull = lambda {|object|
                if object["type"] == "nyxpoint" then
                    uuid = object["uuid"]
                    return [ "nyx point: #{NyxOps::getDescription(uuid)}" , lambda { NyxUserInterface::nyxPointDive(uuid) } ]
                end
                if object["type"] == "tag" then
                    tag = object["tag"]
                    return [ "tag: #{tag}" , lambda { NyxUserInterface::nextGenTagDive(tag) } ]
                end
                nil
            }
            items = globalss
                .map{|object| globalssObjectToMenuItemOrNull.call(object) }
                .compact
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NyxSearch::search()
    def self.search()
        fragment = NyxSearch::nextGenGetSearchFragmentOrNull()
        return if fragment.nil?
        globalss = NyxSearch::nextGenSearchFragmentToGlobalSearchStructure(fragment)
        NyxSearch::globalSearchStructureDive(globalss)
    end
end

class NyxUserInterface

    # NyxUserInterface::nyxTargetDive(nyxuuid, nyxPointTarget)
    def self.nyxTargetDive(nyxuuid, nyxPointTarget)
        puts "-> nyxPointTarget:"
        puts JSON.pretty_generate(nyxPointTarget)
        puts NyxOps::nyxTargetToString(nyxPointTarget)
        NyxOps::openNyxTarget(nyxPointTarget)
    end

    # NyxUserInterface::nyxTargetsDive(nyxuuid)
    def self.nyxTargetsDive(nyxuuid)
        toStringLambda = lambda { |nyxPointTarget| NyxOps::nyxTargetToString(nyxPointTarget) }
        nyxPointTarget = LucilleCore::selectEntityFromListOfEntitiesOrNull("Choose target", NyxOps::getTargets(nyxuuid), toStringLambda)
        return if nyxPointTarget.nil?
        NyxUserInterface::nyxTargetDive(nyxuuid, nyxPointTarget)
    end

    # NyxUserInterface::nyxPointDive(uuid)
    def self.nyxPointDive(uuid)
        loop {
            NyxOps::printNyxDetails(uuid)
            operations = [
                "quick open",
                "edit description",
                "edit reference datetime",
                "targets dive",
                "targets (add new)",
                "targets (select and remove)",
                "tags (add new)",
                "tags (remove)",
                "streams (add new)",
                "streams (remove)",
                "destroy point"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "quick open" then
                NyxOps::optimisticOpen(uuid)
            end
            if operation == "edit description" then
                description = NyxOps::getDescription(uuid)
                description = NyxMiscUtils::editTextUsingTextmate(description).strip
                if description == "" or description.lines.to_a.size != 1 then
                    puts "Descriptions should have one non empty line"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                NyxOps::setDescription(uuid description)

            end
            if operation == "edit reference datetime" then
                referenceDateTime = NyxOps::getReferenceDateTime(uuid)
                referenceDateTime = NyxMiscUtils::editTextUsingTextmate(referenceDateTime).strip
                if NyxMiscUtils::isProperDateTimeIso8601(referenceDateTime) then
                    NyxOps::setReferenceDateTime(uuid, referenceDateTime)
                else
                    puts "I could not validate #{referenceDateTime} as a proper iso8601 datetime"
                    puts "Aborting operation"
                    LucilleCore::pressEnterToContinue()
                end
            end
            if operation == "target dive" then
                NyxUserInterface::nyxTargetDive(uuid, NyxOps::getTargets(uuid).first)
            end
            if operation == "targets dive" then
                NyxUserInterface::nyxTargetsDive(uuid)
            end
            if operation == "targets (add new)" then
                targets = NyxOps::getTargets(uuid)
                target = NyxOps::makeNyxTargetInteractiveOrNull(nil)
                next if target.nil?
                targets << target
                NyxOps::setTargets(uuid, target)
            end
            if operation == "targets (select and remove)" then
                toStringLambda = lambda { |nyxPointTarget| NyxOps::nyxTargetToString(nyxPointTarget) }
                target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", NyxOps::getTargets(uuid), toStringLambda)
                next if target.nil?
                targets = NyxOps::getTargets(uuid).reject{|t| t["uuid"]==target["uuid"] }
                NyxOps::destroyNyxTargetAttempt(target)
            end
            if operation == "tags (add new)" then
                tag = NyxOps::makeOnePermanodeTagInteractiveOrNull()
                next if tag.nil?
                tags = NyxOps::getTags(uuid)
                tags << tag
                NyxOps::setTags(uuid, tags)
            end
            if operation == "tags (remove)" then
                tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", tags)
                next if tag.nil?
                tags = NyxOps::getTags(uuid)
                tags = tags.reject{|t| t == tag }
                NyxOps::setTags(uuid, tags)
            end
            if operation == "streams (add new)" then
                stream = NyxOps::makeOnePermanodeStreamInteractiveOrNull()
                next if stream.nil?
                streams = NyxOps::getStreams(uuid)
                streams << stream
                NyxOps::setStreams(uuid, streams)
            end
            if operation == "streams (remove)" then
                streams = NyxOps::getStreams(uuid)
                stream = LucilleCore::selectEntityFromListOfEntitiesOrNull("stream", streams)
                next if stream.nil?
                streams = streams.reject{|x| x == stream }
                NyxOps::setStreams(uuid, streams)
            end
            if operation == "destroy point" then
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    NyxOps::destroyNyxPointContentsAndPermanode(uuid)
                    return
                end
            end
        }
    end

    # NyxUserInterface::nyxPointsDive(uuids)
    def self.nyxPointsDive(uuids)
        loop {
            uuid = NyxOps::selectNyxUUIDOrNull(uuids)
            break if uuid.nil?
            NyxUserInterface::nyxPointDive(uuid)
        }
    end

    # NyxUserInterface::nextGenTagDive(tag)
    def self.nextGenTagDive(tag)
        loop {
            system('clear')
            puts "Tag diving: #{tag}"
            items = []
            NyxOps::nyxuuids()
                .select{|uuid| NyxOps::nyxPointCarriesTag(uuid, tag) }
                .each{|uuid|
                    items << [ NyxOps::getDescription(uuid) , lambda { NyxUserInterface::nyxPointDive(uuid) } ]
                }
            break if items.empty?
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # ------------------------------------------

    # NyxUserInterface::uimainloop()
    def self.uimainloop()
        loop {
            system("clear")
            puts "Nyx 🗺️"
            operations = [
                # Search
                "search",

                # View
                "show newly created nyx points",
                "nyx point dive (uuid)",

                # Make or modify
                "make new nyx point",

                # Special operations
                "rename tag",
                "rename stream",

                # Destroy
                "nyx point destroy (uuid)",
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "search" then
                NyxSearch::search()
            end
            if operation == "rename tag" then
                oldname = LucilleCore::askQuestionAnswerAsString("old name (capilisation doesn't matter): ")
                next if oldname.size == 0
                newname = LucilleCore::askQuestionAnswerAsString("new name: ")
                next if newname.size == 0
                renameTagIfNeeded = lambda {|tag, oldname, newname|
                    if tag.downcase == oldname.downcase then
                        tag = newname
                    end
                    tag
                }
                NyxOps::nyxuuids()
                    .each{|uuid|
                        tags1 = NyxOps::getTags(uuid)
                        tags2 = tags1.map{|tag| renameTagIfNeeded.call(tag, oldname, newname) }
                        if tags1.join(':') != tags2.join(':') then
                            NyxOps::setTags(uuid, tags2)
                        end
                    }
            end
            if operation == "rename stream" then
                oldname = LucilleCore::askQuestionAnswerAsString("old name (capilisation doesn't matter): ")
                next if oldname.size == 0
                newname = LucilleCore::askQuestionAnswerAsString("new name: ")
                next if newname.size == 0
                renameStreamIfNeeded = lambda {|stream, oldname, newname|
                    if stream.downcase == oldname.downcase then
                        stream = newname
                    end
                    stream
                }
                NyxOps::nyxuuids()
                    .each{|uuid|
                        streams1 = NyxOps::getStreams(uuid)
                        streams2 = streams1.map{|stream| renameStreamIfNeeded.call(stream, oldname, newname) }
                        if streams1.join(':') != streams2.join(':') then
                            NyxOps::setStreams(uuid, stream2)
                        end
                    }
            end
            if operation == "nyx point dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                filepath = NyxEstate::uuid2aetherfilepath(uuid)
                if File.exists?(filepath) then
                    NyxUserInterface::nyxPointDive(uuid)
                else
                    puts "Could not find nyx point for uuid (#{uuid})"
                end
            end
            if operation == "make new nyx point" then
                NyxOps::makePermanode1Interactive()
            end
            if operation == "show newly created nyx points" then
                uuids = NyxOps::nyxuuids()
                                .sort{|uuid1, uuid2| NyxOps::getCreationTimestamp(uuid1) <=> NyxOps::getCreationTimestamp(uuid2) }
                                .reverse
                                .first(20)
                NyxUserInterface::nyxPointsDive(uuids)
            end
            if operation == "nyx point destroy (uuid)" then
                nyxuuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    NyxOps::destroyNyxPointContentsAndPermanode(nyxuuid)
                end
            end
        }
    end
end
