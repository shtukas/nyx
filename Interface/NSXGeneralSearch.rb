
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"

class NSXGeneralSearch

    # NSXGeneralSearch::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        [
            Quarks::searchNx1630(pattern),
            Cliques::searchNx1630(pattern),
            QuarkTags::searchNx1630(pattern),
            Waves::searchNx1630(pattern)
        ]
            .flatten
            .sort{|i1, i2| i1["referencetime"] <=> i2["referencetime"] }
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