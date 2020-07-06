
# encoding: UTF-8

require_relative "LucilleCore.rb"

require_relative "Common.rb"
require_relative "Quarks.rb"
require_relative "Cliques.rb"

# -----------------------------------------------------------------

class NSXGeneralSearch

    # NSXGeneralSearch::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        [
            Cliques::searchNx1630(pattern).sort{|i1, i2| i1["referencetime"] <=> i2["referencetime"] },
            Quarks::searchNx1630(pattern).sort{|i1, i2| i1["referencetime"] <=> i2["referencetime"] },
            Waves::searchNx1630(pattern).sort{|i1, i2| i1["referencetime"] <=> i2["referencetime"] }
        ]
            .flatten
    end

    # NSXGeneralSearch::searchAndDive()
    def self.searchAndDive()
        loop {
            system("clear")
            pattern = LucilleCore::askQuestionAnswerAsString("search pattern: ")
            return if pattern.size == 0
            next if pattern.size < 3
            searchresults = NSXGeneralSearch::searchNx1630(pattern)
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