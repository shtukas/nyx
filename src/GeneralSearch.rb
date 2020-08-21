
# encoding: UTF-8

class GeneralSearch

    # GeneralSearch::searchNx1630Node(pattern)
    def self.searchNx1630Node(pattern)
        SelectionLookupDataset::patternToNodes(pattern)
            .map{|node|
                {
                    "description"   => NSDataType1::toString(node),
                    "referencetime" => NSDataType1::getReferenceUnixtime(node),
                    "dive"          => lambda{ NSDataType1::landing(node) }
                }
            }
    end

    # GeneralSearch::searchNx1630Dataline(pattern)
    def self.searchNx1630Dataline(pattern)
        SelectionLookupDataset::patternToDatalines(pattern)
            .map{|dataline|
                {
                    "description"   => NSDataLine::toString(dataline),
                    "referencetime" => dataline["unixtime"],
                    "dive"          => lambda{ NSDataLine::landing(dataline) }
                }
            }
    end

    # GeneralSearch::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        [
            GeneralSearch::searchNx1630Node(pattern),
            GeneralSearch::searchNx1630Dataline(pattern),
            Waves::searchNx1630(pattern)
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