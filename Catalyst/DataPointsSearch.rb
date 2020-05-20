
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPointsSearch.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTargets.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Bank.rb"
=begin 
    Bank::put(uuid, weight, validityTimespan)
    Bank::total(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"

# -----------------------------------------------------------------

class DataPointsSearch

    # DataPointsSearch::tags()
    def self.tags()
        DataPoints::datapoints()
            .map{|point| point["tags"] }
            .flatten
            .uniq
            .sort
    end

    # DataPointsSearch::getPointsForTag(tag)
    def self.getPointsForTag(tag)
        DataPoints::datapoints().select{|point|
            point["tags"].include?(tag)
        }
    end

    # DataPointsSearch::selectDataPointOrNull(points)
    def self.selectDataPointOrNull(points)
        descriptionXp = lambda { |point|
            "#{point["description"]} (#{point["uuid"][0,4]})"
        }
        descriptionsxp = points.map{|point| descriptionXp.call(point) }
        selectedDescriptionxp = CatalystCommon::chooseALinePecoStyle("select datapoint (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        point = points.select{|point| descriptionXp.call(point) == selectedDescriptionxp }.first
        return nil if point.nil?
        point
    end

    # DataPointsSearch::pointsDive(points)
    def self.pointsDive(points)
        loop {
            point = DataPointsSearch::selectDataPointOrNull(points)
            break if point.nil?
            DataPoints::pointDive(point)
        }
    end

    # DataPointsSearch::tagDive(tag)
    def self.tagDive(tag)
        loop {
            system('clear')
            puts "Data Points Tag Diving: #{tag}"
            items = []
            DataPoints::datapoints()
                .select{|point| point["tags"].map{|tag| tag.downcase }.include?(tag.downcase) }
                .each{|point|
                    items << [ point["description"] , lambda { DataPoints::pointDive(point) } ]
                }
            break if items.empty?
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # DataPointsSearch::searchPatternToTags(searchPattern)
    def self.searchPatternToTags(searchPattern)
        DataPointsSearch::tags()
            .select{|tag| tag.downcase.include?(searchPattern.downcase) }
    end

    # DataPointsSearch::searchPatternToPoints(searchPattern)
    def self.searchPatternToPoints(searchPattern)
        DataPoints::datapoints()
            .select{|point| point["description"].downcase.include?(searchPattern.downcase) }
    end

    # DataPointsSearch::searchPatternToDataPointsDescriptions(searchPattern)
    def self.searchPatternToDataPointsDescriptions(searchPattern)
        DataPointsSearch::searchPatternToPoints(searchPattern)
            .map{|point| point["description"] }
            .uniq
            .sort
    end

    # DataPointsSearch::nextGenGetSearchFragmentOrNull()
    def self.nextGenGetSearchFragmentOrNull() # () -> String
        LucilleCore::askQuestionAnswerAsString("search fragment: ")
    end

    # DataPointsSearch::nextGenSearchFragmentToGlobalSearchStructure(fragment)
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
        objs1 = DataPointsSearch::searchPatternToPoints(fragment)
                    .map{|point| 
                        {
                            "type" => "point",
                            "point" => point
                        }
                    }
        objs2 = DataPointsSearch::searchPatternToTags(fragment)
                    .map{|tag|
                        {
                            "type" => "tag",
                            "tag" => tag
                        }
                    }
        objs1 + objs2
    end

    # DataPointsSearch::globalSearchStructureDive(globalss)
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
                    return [ "tag: #{tag}" , lambda { DataPointsSearch::tagDive(tag) } ]
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

    # DataPointsSearch::search()
    def self.search()
        fragment = DataPointsSearch::nextGenGetSearchFragmentOrNull()
        return if fragment.nil?
        globalss = DataPointsSearch::nextGenSearchFragmentToGlobalSearchStructure(fragment)
        DataPointsSearch::globalSearchStructureDive(globalss)
    end
end
