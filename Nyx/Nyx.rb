
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

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/AtlasCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CoreData.rb"
=begin

    CoreDataFile::copyFileToRepository(filepath)
    CoreDataFile::filenameToFilepath(filename)
    CoreDataFile::exists?(filename)
    CoreDataFile::openOrCopyToDesktop(filename)

    CoreDataDirectory::copyFolderToRepository(folderpath)
    CoreDataDirectory::foldernameToFolderpath(foldername)
    CoreDataDirectory::openFolder(foldername)

=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

# --------------------------------------------------------------------

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

class NyxPoints
    # NyxPoints::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NyxPoints::pathToPoints()
    def self.pathToPoints()
        "/Users/pascal/Galaxy/DataBank/Catalyst/NyxPoints"
    end

    # NyxPoints::points()
    def self.points()
        Dir.entries(NyxPoints::pathToPoints())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{NyxPoints::pathToPoints()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationTimestamp"] <=> c2["creationTimestamp"] }
    end

    # NyxPoints::getPointByUUIDOrNUll(uuid)
    def self.getPointByUUIDOrNUll(uuid)
        filepath = "#{NyxPoints::pathToPoints()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NyxPoints::save(point)
    def self.save(point)
        uuid = point["uuid"]
        File.open("#{NyxPoints::pathToPoints()}/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(point)) }
    end

    # NyxPoints::destroy(point)
    def self.destroy(point)
        uuid = point["uuid"]
        filepath = "#{NyxPoints::pathToPoints()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NyxPoints::makePoint(uuid, creationTimestamp, referenceDateTime, description, targets, taxonomy)
    def self.makePoint(uuid, creationTimestamp, referenceDateTime, description, targets, taxonomy)
        {
            "uuid"              => uuid,
            "creationTimestamp" => creationTimestamp,
            "referenceDateTime" => referenceDateTime,
            "description"       => description,
            "targets"           => targets,
            "taxonomy"              => taxonomy
        }
    end

    # NyxPoints::issuePoint(uuid, creationTimestamp, referenceDateTime, description, targets, taxonomy)
    def self.issuePoint(uuid, creationTimestamp, referenceDateTime, description, targets, taxonomy)
        point = NyxPoints::makePoint(uuid, creationTimestamp, referenceDateTime, description, targets, taxonomy)
        NyxPoints::save(point)
    end
end

class NyxOps

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

    # NyxOps::printPointDetails(uuid)
    def self.printPointDetails(point)
        puts "Permanode:"
        puts "    uuid: #{point["uuid"]}"
        puts "    description: #{point["description"].green}"
        puts "    datetime: #{point["referenceDateTime"]}"
        puts "    targets:"
        point["targets"]
            .each{|target|
                puts "        #{NyxOps::nyxTargetToString(target)}"
            }
        if point["taxonomy"].empty? then
            puts "    taxonomy: (empty set)".green
        else
            puts "    taxonomy"
            point["taxonomy"].each{|item|
                puts "        #{item}".green
            }
        end
    end

    # ------------------------------------------
    # Opening

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

    # NyxOps::openPoint(point)
    def self.openPoint(point)
        NyxOps::printPointDetails(point)
        puts "    -> Opening..."
        if point["targets"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find target for this nyx point. Dive? ") then
                NyxUserInterface::pointDive(point)
            end
            return
        end
        target = nil
        if point["targets"].size == 1 then
            target = point["targets"].first
        else
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target:", point["targets"], lambda{|target| NyxOps::nyxTargetToString(target) })
        end
        puts JSON.pretty_generate(target)
        NyxOps::openNyxTarget(target)
    end

    # ------------------------------------------------------------------
    # Data Queries and Data Manipulations

    # NyxOps::selectNyxPointOrNull(points)
    def self.selectNyxPointOrNull(points)
        descriptionXp = lambda { |point|
            "#{point["description"]} (#{point["uuid"][0,4]})"
        }
        descriptionsxp = points.map{|point| descriptionXp.call(point) }
        selectedDescriptionxp = NyxMiscUtils::chooseALinePecoStyle("select nyx point (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        point = points.select{|point| descriptionXp.call(point) == selectedDescriptionxp }.first
        return nil if point.nil?
        point
    end

    # NyxOps::getNyxUUIDsCarryingThisDirectoryMark(mark)
    def self.getNyxUUIDsCarryingThisDirectoryMark(mark)
        NyxPoints::points()
            .select{|point|
                point["targets"].any?{|target| target["type"] == "lstore-directory-mark-BEE670D0" and target["mark"] == mark }
            }
    end

    # NyxOps::taxonomy()
    def self.taxonomy()
        NyxPoints::points()
            .map{|point| point["taxonomy"] }
            .flatten
            .uniq
            .sort
    end

    # NyxOps::getPointsForTag(taxo)
    def self.getPointsForTag(taxo)
        NyxPoints::points().select{|point|
            point["taxonomy"].include?(taxo)
        }
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
        targetType =
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
        return nil if targetType.nil?
        if targetType == "url-EFB8D55B" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url"  => LucilleCore::askQuestionAnswerAsString("url: ").strip
            }
        end
        if targetType == "file-3C93365A" then
            return NyxOps::makeNyxTargetFileInteractiveOrNull()
        end
        if targetType == "unique-name-C2BF46D6" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => LucilleCore::askQuestionAnswerAsString("uniquename: ").strip
            }
        end
        if targetType == "lstore-directory-mark-BEE670D0" then
            return NyxOps::makeNyxTargetLStoreDirectoryMarkInteractiveOrNull()
        end
        if targetType == "perma-dir-11859659" then
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
        taxo = LucilleCore::askQuestionAnswerAsString("taxo (empty for exit): ")
        return nil if taxo == ""
        taxo
    end

    # NyxOps::makePermanodeTagsInteractive()
    def self.makePermanodeTagsInteractive()
        taxonomy = []
        loop {
            taxo = NyxOps::makeOnePermanodeTagInteractiveOrNull()
            break if taxo.nil?
            taxonomy << taxo
        }
        taxonomy
    end

    # NyxOps::makeNyxPointInteractivePart2(description, target)
    def self.makeNyxPointInteractivePart2(description, target)
        uuid = SecureRandom.uuid
        creationTimestamp = Time.new.to_f
        referenceDateTime = Time.now.utc.iso8601
        targets = [ target ]
        taxonomy = NyxOps::makePermanodeTagsInteractive()
        NyxPoints::issuePoint(uuid, creationTimestamp, referenceDateTime, description, targets, taxonomy)
    end

    # NyxOps::makeNyxPointInteractivePart1()
    def self.makeNyxPointInteractivePart1()
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
            target = {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url" => url
            }
            NyxOps::makeNyxPointInteractivePart2(description, target)
        end

        if operation == "uniquename" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            target = {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => uniquename
            }
            NyxOps::makeNyxPointInteractivePart2(description, target)
        end

        if operation == "file (from desktop)" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            target = NyxOps::makeNyxTargetFileInteractiveOrNull()
            return if target.nil?
            NyxOps::makeNyxPointInteractivePart2(description, target)
        end

        if operation == "lstore-directory-mark" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            target = NyxOps::makeNyxTargetLStoreDirectoryMarkInteractiveOrNull()
            return if target.nil?
            NyxOps::makeNyxPointInteractivePart2(description, target)
        end

        if operation == "Desktop files inside permadir" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            locations = NyxMiscUtils::selectOneOrMoreFilesOnTheDesktopByLocation()

            foldername2 = NyxMiscUtils::l22()
            folderpath2 = CoreDataDirectory::foldernameToFolderpath(foldername2)
            FileUtils.mkdir(folderpath2)

            target = {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
            NyxOps::makeNyxPointInteractivePart2(description, target)

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
            return
        end
        raise "[error: 15c46fdd]"
    end

    # NyxOps::destroyPointContentsAndPoint(point)
    def self.destroyPointContentsAndPoint(point)
        point["targets"].all?{|target| NyxOps::destroyNyxTargetAttempt(target) }
        NyxPoints::destroy(point)
    end
end

class NyxSearch

    # NyxSearch::searchPatternToTaxos(searchPattern)
    def self.searchPatternToTaxos(searchPattern)
        NyxOps::taxonomy()
            .select{|taxo| taxo.downcase.include?(searchPattern.downcase) }
    end

    # NyxSearch::searchPatternToPoints(searchPattern)
    def self.searchPatternToPoints(searchPattern)
        NyxPoints::points()
            .select{|point| point["description"].downcase.include?(searchPattern.downcase) }
    end

    # NyxSearch::searchPatternToNyxPointsDescriptions(searchPattern)
    def self.searchPatternToNyxPointsDescriptions(searchPattern)
        NyxSearch::searchPatternToPoints(searchPattern)
            .map{|point| point["description"] }
            .uniq
            .sort
    end

    # NyxSearch::nextGenGetSearchFragmentOrNull()
    def self.nextGenGetSearchFragmentOrNull() # () -> String
        LucilleCore::askQuestionAnswerAsString("search fragment: ")
    end

    # NyxSearch::nextGenSearchFragmentToGlobalSearchStructure(fragment)
    # Objects returned by the function: they are essentially search results.
    # {
    #     "type" => "point",
    #     "point" => point
    # }
    # {
    #     "type" => "taxo",
    #     "taxo" => taxo
    # }
    def self.nextGenSearchFragmentToGlobalSearchStructure(fragment)
        objs1 = NyxSearch::searchPatternToPoints(fragment)
                    .map{|point| 
                        {
                            "type" => "point",
                            "point" => point
                        }
                    }
        objs2 = NyxSearch::searchPatternToTaxos(fragment)
                    .map{|taxo|
                        {
                            "type" => "taxo",
                            "taxo" => taxo
                        }
                    }
        objs1 + objs2
    end

    # NyxSearch::globalSearchStructureDive(globalss)
    def self.globalSearchStructureDive(globalss)
        loop {
            system("clear")
            globalssObjectToMenuItemOrNull = lambda {|object|
                if object["type"] == "point" then
                    point = object["point"]
                    return [ "nyx point: #{point["description"]}" , lambda { NyxUserInterface::pointDive(point) } ]
                end
                if object["type"] == "taxo" then
                    taxo = object["taxo"]
                    return [ "taxo: #{taxo}" , lambda { NyxUserInterface::taxoDive(taxo) } ]
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

    # NyxUserInterface::targetDive(target)
    def self.targetDive(target)
        puts "-> target:"
        puts JSON.pretty_generate(target)
        puts NyxOps::nyxTargetToString(target)
        NyxOps::openNyxTarget(target)
    end

    # NyxUserInterface::targetsDive(targets)
    def self.targetsDive(targets)
        toStringLambda = lambda { |target| NyxOps::nyxTargetToString(target) }
        target = LucilleCore::selectEntityFromListOfEntitiesOrNull("Choose target", targets, toStringLambda)
        return if target.nil?
        NyxUserInterface::targetDive(target)
    end

    # NyxUserInterface::pointDive(point)
    def self.pointDive(point)
        loop {
            NyxOps::printPointDetails(point)
            operations = [
                "open",
                "edit description",
                "edit reference datetime",
                "target(s) dive",
                "targets (add new)",
                "targets (select and remove)",
                "taxonomy (add new)",
                "taxonomy (remove)",
                "destroy point"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "open" then
                NyxOps::openPoint(point)
            end
            if operation == "edit description" then
                point["description"] = NyxMiscUtils::editTextUsingTextmate(point["description"]).strip
                if description == "" or description.lines.to_a.size != 1 then
                    puts "Descriptions should be one non empty line"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                NyxPoints::save(point)
            end
            if operation == "edit reference datetime" then
                referenceDateTime = NyxMiscUtils::editTextUsingTextmate(point["referenceDateTime"]).strip
                if NyxMiscUtils::isProperDateTimeIso8601(referenceDateTime) then
                    point["referenceDateTime"] = referenceDateTime
                    NyxPoints::save(point)
                else
                    puts "I could not validate #{referenceDateTime} as a proper iso8601 datetime"
                    puts "Aborting operation"
                    LucilleCore::pressEnterToContinue()
                end
            end
            if operation == "target(s) dive" then
                if point["targets"].size == 1 then
                    NyxUserInterface::targetDive(point["targets"][0])
                else
                    NyxUserInterface::targetsDive(point["targets"])
                end
            end
            if operation == "targets (add new)" then
                target = NyxOps::makeNyxTargetInteractiveOrNull(nil)
                next if target.nil?
                point["targets"] << target
                NyxPoints::save(point)
            end
            if operation == "targets (select and remove)" then
                toStringLambda = lambda { |target| NyxOps::nyxTargetToString(target) }
                target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", point["targets"], toStringLambda)
                next if target.nil?
                point["targets"] = point["targets"].reject{|t| t["uuid"]==target["uuid"] }
                NyxPoints::save(point)
                NyxOps::destroyNyxTargetAttempt(target)
            end
            if operation == "taxonomy (add new)" then
                taxo = NyxOps::makeOnePermanodeTagInteractiveOrNull()
                next if taxo.nil?
                point["taxonomy"] << taxo
                NyxPoints::save(point)
            end
            if operation == "taxonomy (remove)" then
                taxo = LucilleCore::selectEntityFromListOfEntitiesOrNull("taxo", point["taxonomy"])
                next if taxo.nil?
                point["taxonomy"] = point["taxonomy"].reject{|t| t == taxo }
                NyxPoints::save(point)
            end
            if operation == "destroy point" then
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    NyxOps::destroyPointContentsAndPoint(point)
                    return
                end
            end
        }
    end

    # NyxUserInterface::pointsDive(points)
    def self.pointsDive(points)
        loop {
            point = NyxOps::selectNyxPointOrNull(points)
            break if point.nil?
            NyxUserInterface::pointDive(point)
        }
    end

    # NyxUserInterface::taxoDive(taxo)
    def self.taxoDive(taxo)
        loop {
            system('clear')
            puts "Tag diving: #{taxo}"
            items = []
            NyxPoints::points()
                .select{|point| point["taxonomy"].map{|taxo| taxo.downcase }.include?(taxo.downcase) }
                .each{|point|
                    items << [ point["description"] , lambda { NyxUserInterface::pointDive(point) } ]
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
                "repair json (uuid)",

                # Make or modify
                "make new nyx point",

                # Special operations
                "rename taxo",

                # Destroy
                "nyx point destroy (uuid)",
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "search" then
                NyxSearch::search()
            end
            if operation == "rename taxo" then
                oldname = LucilleCore::askQuestionAnswerAsString("old name (capilisation doesn't matter): ")
                next if oldname.size == 0
                newname = LucilleCore::askQuestionAnswerAsString("new name: ")
                next if newname.size == 0
                renameTagIfNeeded = lambda {|taxo, oldname, newname|
                    if taxo.downcase == oldname.downcase then
                        taxo = newname
                    end
                    taxo
                }
                NyxPoints::points()
                    .each{|point|
                        uuid = point["uuid"]
                        taxonomy1 = point["taxonomy"]
                        taxonomy2 = taxonomy1.map{|taxo| renameTagIfNeeded.call(taxo, oldname, newname) }
                        if taxonomy1.join(':') != taxonomy2.join(':') then
                            point["taxonomy"] = taxonomy2
                            NyxPoints::save(point)
                        end
                    }
            end
            if operation == "nyx point dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                point = NyxPoints::getPointByUUIDOrNUll(uuid)
                if point then
                    NyxUserInterface::pointDive(point)
                else
                    puts "Could not find nyx point for uuid (#{uuid})"
                end
            end
            if operation == "repair json (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                point = NyxPoints::getPointByUUIDOrNUll(uuid)
                if point then
                    pointjson = CatalystCommon::editTextUsingTextmate(JSON.pretty_generate(point))
                    point = JSON.parse(pointjson)
                    NyxPoints::save(point)
                else
                    puts "Could not find nyx point for uuid (#{uuid})"
                end
            end
            if operation == "make new nyx point" then
                NyxOps::makeNyxPointInteractivePart1()
            end
            if operation == "show newly created nyx points" then
                points = NyxPoints::points()
                            .sort{|p1, p2| p1["creationTimestamp"] <=> p2["creationTimestamp"] }
                            .reverse
                            .first(20)
                NyxUserInterface::pointsDive(points)
            end
            if operation == "nyx point destroy (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                point = NyxPoints::getPointByUUIDOrNUll(uuid)
                next if point.nil?
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    NyxOps::destroyPointContentsAndPoint(point)
                end
            end
        }
    end
end

