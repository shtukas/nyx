
# encoding: UTF-8

class Search

    # Search::nx20s() # Array[Nx20]
    def self.nx20s()
        (NxTodos::items() + Waves::items() + Nx8::items() + NxLines::items())
            .map{|item|
                {
                    "announce" => "(#{item["mikuType"]}) #{PolyFunctions::genericDescriptionOrNull(item)}",
                    "unixtime" => item["unixtime"],
                    "item"     => item
                }
            }
    end

    # Search::catalyst()
    def self.catalyst()
        mikuTypes = ["NxTodo", "Wave"]
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Search::nx20s()
                            .select{|nx20| mikuTypes.include?(nx20["item"]["mikuType"]) }
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Search::nx20s()
                                .select{|nx20| mikuTypes.include?(nx20["item"]["mikuType"]) }
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|i| i["announce"] })
                break if nx20.nil?
                PolyActions::landing(nx20["item"])
            }
        }
        nil
    end

    # Search::nyx()
    def self.nyx()
        mikuTypes = ["Nx8", "NxLine"]
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Search::nx20s()
                            .select{|nx20| mikuTypes.include?(nx20["item"]["mikuType"]) }
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Search::nx20s()
                                .select{|nx20| mikuTypes.include?(nx20["item"]["mikuType"]) }
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|packet| PolyFunctions::toStringForListing(packet["item"]) })
                break if nx20.nil?
                PolyActions::landing(nx20["item"])
            }
        }
        nil
    end

    # Search::foxTerrier() # nil or Item
    def self.foxTerrier()
        mikuTypes = ["Nx7"]
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            return nil if fragment == ""
            nx20 = Search::nx20s()
                        .select{|nx20| mikuTypes.include?(nx20["item"]["mikuType"]) }
                        .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if nx20.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                nx20 = Search::nx20s()
                            .select{|nx20| mikuTypes.include?(nx20["item"]["mikuType"]) }
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                            .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", nx20, lambda{|packet| PolyFunctions::toStringForListing(packet["item"]) })
                break if nx20.nil?
                system('clear')
                itemOpt = PolyFunctions::foxTerrierAtItem(nx20["item"])
                return itemOpt if itemOpt
            }
        }
        nil
    end
end
