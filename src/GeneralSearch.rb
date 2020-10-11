
# encoding: UTF-8

class GeneralSearch

    # GeneralSearch::searchNx1630Datapoint(pattern)
    def self.searchNx1630Datapoint(pattern)
        SelectionLookupDataset::patternToDatapoints(pattern)
            .map{|datapoint|
                {
                    "description"   => NSNode1638::toString(datapoint),
                    "referencetime" => DateTime.parse(NyxObjectInterface::getObjectReferenceDateTime(datapoint)).to_time.to_f,
                    "dive"          => lambda{ NSNode1638::landing(datapoint) }
                }
            }
    end

    # GeneralSearch::searchNx1630Page(pattern)
    def self.searchNx1630Page(pattern)
        SelectionLookupDataset::patternToPages(pattern)
            .map{|page|
                {
                    "description"   => Pages::toString(page),
                    "referencetime" => DateTime.parse(NyxObjectInterface::getObjectReferenceDateTime(page)).to_time.to_f,
                    "dive"          => lambda{ Pages::landing(page) }
                }
            }
    end

    # GeneralSearch::searchNx1630Tag(pattern)
    def self.searchNx1630Tag(pattern)
        SelectionLookupDataset::patternToTags(pattern)
            .map{|tag|
                {
                    "description"   => Tags::toString(tag),
                    "referencetime" => DateTime.parse(NyxObjectInterface::getObjectReferenceDateTime(tag)).to_time.to_f,
                    "dive"          => lambda{ Tags::landing(tag) }
                }
            }
    end

    # GeneralSearch::searchNx1630Asteroid(pattern)
    def self.searchNx1630Asteroid(pattern)
        SelectionLookupDataset::patternToAsteroids(pattern)
            .map{|asteroid|
                {
                    "description"   => Asteroids::toString(asteroid),
                    "referencetime" => asteroid["unixtime"],
                    "dive"          => lambda{ Asteroids::landing(asteroid) }
                }
            }
    end

    # GeneralSearch::searchNx1630Wave(pattern)
    def self.searchNx1630Wave(pattern)
        SelectionLookupDataset::patternToWaves(pattern)
            .map{|wave|
                {
                    "description"   => Waves::toString(wave),
                    "referencetime" => wave["unixtime"],
                    "dive"          => lambda { Waves::waveDive(wave) }
                }
            }
    end

    # GeneralSearch::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        [
            GeneralSearch::searchNx1630Datapoint(pattern),
            GeneralSearch::searchNx1630Page(pattern),
            GeneralSearch::searchNx1630Tag(pattern),
            GeneralSearch::searchNx1630Asteroid(pattern),
            GeneralSearch::searchNx1630Wave(pattern)
        ]
            .flatten
            .sort{|i1, i2| i1["referencetime"] <=> i2["referencetime"] }
    end

    # GeneralSearch::searchAndDive()
    def self.searchAndDive()
        loop {
            system("clear")
            pattern = LucilleCore::askQuestionAnswerAsString("search pattern: ")
            return if pattern.size == 0
            next if pattern.size < 3
            searchresults = GeneralSearch::searchNx1630(pattern)
            loop {
                system("clear")
                puts "results for '#{pattern}':"
                ms = LCoreMenuItemsNX1.new()
                searchresults
                    .each{|sr| 
                        ms.item(
                            sr["description"], 
                            sr["dive"]
                        )
                    }
                status = ms.promptAndRunSandbox()
                break if !status
            }
        }
    end
end