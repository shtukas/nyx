
# encoding: UTF-8

class GeneralSearch

    # GeneralSearch::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        [
            NSDataType2::searchNx1630(pattern).sort{|i1, i2| i1["referencetime"] <=> i2["referencetime"] },
            Waves::searchNx1630(pattern).sort{|i1, i2| i1["referencetime"] <=> i2["referencetime"] }
        ]
            .flatten
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
                status = ms.prompt()
                break if !status
            }
        }
    end
end