
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

class NSXGeneralSearch

    # NSXGeneralSearch::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        [
            Quarks::searchNx1630(pattern),
            Cliques::searchNx1630(pattern)
        ]
            .flatten
            .sort{|i1, i2| i1["referencetime"] <=> i2["referencetime"] }
    end

    # NSXGeneralSearch::searchAndDive()
    def self.searchAndDive()
        pattern = LucilleCore::askQuestionAnswerAsString("search pattern: ")
        items = NSXGeneralSearch::searchNx1630(pattern)
        items = items.map{|item| [ item["description"], item["dive"] ] }
        loop {
            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end
end