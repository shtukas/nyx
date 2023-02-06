
# encoding: UTF-8

class SearchCatalyst

    # SearchCatalyst::nx20s() # Array[Nx20]
    def self.nx20s()
        Catalyst::catalystItems()
            .map{|item|
                {
                    "announce" => "(#{item["mikuType"]}) #{PolyFunctions::toStringForSearchListing(item)}",
                    "unixtime" => item["unixtime"],
                    "item"     => item
                }
            }
    end

    # SearchCatalyst::run()
    def self.run()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = SearchCatalyst::nx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = SearchCatalyst::nx20s()
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|i| i["announce"] })
                break if nx20.nil?
                puts PolyFunctions::access(nx20["item"])
            }
        }
        nil
    end
end

class SearchNyx

    # SearchNyx::nx20s() # Array[Nx20]
    def self.nx20s()
        NxNodes::items()
            .map{|item|
                {
                    "announce" => "(node) #{PolyFunctions::toStringForSearchListing(item)}",
                    "unixtime" => item["unixtime"],
                    "item"     => item
                }
            }
    end

    # SearchNyx::run()
    def self.run()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = SearchNyx::nx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = SearchNyx::nx20s()
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|i| i["announce"] })
                break if nx20.nil?
                NxNodes::landing(nx20["item"])
            }
        }
        nil
    end
end
