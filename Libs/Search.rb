
# encoding: UTF-8

class SearchCatalyst

    # SearchCatalyst::catalystNx20s() # Array[Nx20]
    def self.catalystNx20s()
        Catalyst::catalystItems()
            .map{|item|
                {
                    "announce" => "(#{item["mikuType"]}) #{PolyFunctions::genericDescription(item)}",
                    "unixtime" => item["unixtime"],
                    "item"     => item
                }
            }
    end

    # SearchCatalyst::catalyst()
    def self.catalyst()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = SearchCatalyst::catalystNx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = SearchCatalyst::catalystNx20s()
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|i| i["announce"] })
                break if nx20.nil?
                PolyActions::probe(nx20["item"])
            }
        }
        nil
    end
end
