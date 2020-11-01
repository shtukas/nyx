
# encoding: UTF-8

class GeneralSearch

    # GeneralSearch::searchNx1630Datapoint(pattern)
    def self.searchNx1630Datapoint(pattern)
        SelectionLookupDataset::patternToDatapoints(pattern)
            .map{|datapoint|
                {
                    "description"   => NGX15::toString(datapoint),
                    "referencetime" => DateTime.parse(NyxObjectInterface::getObjectReferenceDateTime(datapoint)).to_time.to_f,
                    "dive"          => lambda{ NGX15::landing(datapoint) }
                }
            }
    end

    # GeneralSearch::searchNx1630Quark(pattern)
    def self.searchNx1630Quark(pattern)
        SelectionLookupDataset::patternToQuarks(pattern)
            .map{|quark|
                {
                    "description"   => Quark::toString(quark),
                    "referencetime" => DateTime.parse(NyxObjectInterface::getObjectReferenceDateTime(quark)).to_time.to_f,
                    "dive"          => lambda{ Quark::landing(quark) }
                }
            }
    end

    # GeneralSearch::searchNx1630Set(pattern)
    def self.searchNx1630Set(pattern)
        SelectionLookupDataset::patternToSets(pattern)
            .map{|set|
                {
                    "description"   => Tags::toString(set),
                    "referencetime" => DateTime.parse(NyxObjectInterface::getObjectReferenceDateTime(set)).to_time.to_f,
                    "dive"          => lambda{ Tags::landing(set) }
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
            GeneralSearch::searchNx1630Quark(pattern),
            GeneralSearch::searchNx1630Set(pattern),
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
                puts "search results for '#{pattern}':"
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