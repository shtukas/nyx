
# encoding: UTF-8

class Search

    # Search::navigation()
    def self.navigation()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Items::nx20s()
                            .select{|nx20| !nx20["announce"].nil? }
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Items::nx20s()
                                .select{|nx20| !nx20["announce"].nil? }
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|i| i["announce"] })
                break if nx20.nil?
                PolyActions::landing(nx20["item"])
            }
        }
        nil
    end

    # Search::foxTerrier() # nil or Item
    def self.foxTerrier()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            return nil if fragment == ""
            nx20 = Items::nx20s()
                        .select{|nx20| !nx20["announce"].nil? }
                        .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if nx20.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                nx20 = Items::nx20s()
                            .select{|nx20| !nx20["announce"].nil? }
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", nx20, lambda{|item| item["announce"] })
                break if nx20.nil?
                system('clear')
                itemOpt = PolyFunctions::foxTerrierAtItem(nx20["item"])
                return itemOpt if itemOpt
            }
        }
        nil
    end
end
