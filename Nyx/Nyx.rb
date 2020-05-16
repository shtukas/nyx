
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTarget.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

# --------------------------------------------------------------------

class NyxMiscUtils

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
            .map{|filepath| 
                nyxpoint =JSON.parse(IO.read(filepath))
                DataPoints::getOrNull(nyxpoint["uuid"])
            }
            .compact
            .sort{|c1, c2| c1["creationTimestamp"] <=> c2["creationTimestamp"] }
    end

    # NyxPoints::save(point)
    def self.save(point)
        DataPoints::save(point) # Nyx points are datapoints
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

    # NyxPoints::issuePoint(uuid, creationTimestamp, description, targets, tags)
    def self.issuePoint(uuid, creationTimestamp, description, targets, tags)
        point = {
            "uuid"              => uuid,
            "creationTimestamp" => creationTimestamp,
            "description"       => description,
            "targets"           => targets,
            "tags"              => tags
        }
        NyxPoints::save(point)
    end
end

class NyxOps

    # ------------------------------------------------------------------
    # To Strings

    # ------------------------------------------
    # Opening



    # ------------------------------------------------------------------
    # Data Queries and Data Manipulations

    # NyxOps::selectNyxPointOrNull(points)
    def self.selectNyxPointOrNull(points)
        descriptionXp = lambda { |point|
            "#{point["description"]} (#{point["uuid"][0,4]})"
        }
        descriptionsxp = points.map{|point| descriptionXp.call(point) }
        selectedDescriptionxp = NyxMiscUtils::chooseALinePecoStyle("select datapoint (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        point = points.select{|point| descriptionXp.call(point) == selectedDescriptionxp }.first
        return nil if point.nil?
        point
    end

    # NyxOps::tags()
    def self.tags()
        NyxPoints::points()
            .map{|point| point["tags"] }
            .flatten
            .uniq
            .sort
    end

    # NyxOps::getPointsForTag(tag)
    def self.getPointsForTag(tag)
        NyxPoints::points().select{|point|
            point["tags"].include?(tag)
        }
    end

    # ------------------------------------------------------------------
    # Interactive Makers

    # NyxOps::makeOnePermanodeTagInteractiveOrNull()
    def self.makeOnePermanodeTagInteractiveOrNull()
        tag = LucilleCore::askQuestionAnswerAsString("tag (empty for exit): ")
        return nil if tag == ""
        tag
    end

    # NyxOps::makePermanodeTagsInteractive()
    def self.makePermanodeTagsInteractive()
        tags = []
        loop {
            tag = NyxOps::makeOnePermanodeTagInteractiveOrNull()
            break if tag.nil?
            tags << tag
        }
        tags
    end

    # ------------------------------------------------------------------
    # Destroy

    # NyxOps::destroyPointContentsAndPoint(point)
    def self.destroyPointContentsAndPoint(point)
        NyxPoints::destroy(point)
    end
end

class NyxSearch

    # NyxSearch::searchPatternToTags(searchPattern)
    def self.searchPatternToTags(searchPattern)
        NyxOps::tags()
            .select{|tag| tag.downcase.include?(searchPattern.downcase) }
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
    #     "type" => "tag",
    #     "tag" => tag
    # }
    def self.nextGenSearchFragmentToGlobalSearchStructure(fragment)
        objs1 = NyxSearch::searchPatternToPoints(fragment)
                    .map{|point| 
                        {
                            "type" => "point",
                            "point" => point
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
                if object["type"] == "point" then
                    point = object["point"]
                    return [ "datapoint: #{point["description"]}" , lambda { DataPoints::pointDive(point) } ]
                end
                if object["type"] == "tag" then
                    tag = object["tag"]
                    return [ "tag: #{tag}" , lambda { NyxUserInterface::tagDive(tag) } ]
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

    # NyxUserInterface::pointsDive(points)
    def self.pointsDive(points)
        loop {
            point = NyxOps::selectNyxPointOrNull(points)
            break if point.nil?
            DataPoints::pointDive(point)
        }
    end

    # NyxUserInterface::tagDive(tag)
    def self.tagDive(tag)
        loop {
            system('clear')
            puts "Tag diving: #{tag}"
            items = []
            NyxPoints::points()
                .select{|point| point["tags"].map{|tag| tag.downcase }.include?(tag.downcase) }
                .each{|point|
                    items << [ point["description"] , lambda { DataPoints::pointDive(point) } ]
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
            puts "Nyx (Search for some datapoints , phased out) 🗺️"
            operations = [
                "search"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "search" then
                NyxSearch::search()
            end
        }
    end
end

