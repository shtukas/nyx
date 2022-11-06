
# encoding: UTF-8

class Search

    # Search::catalystNx20s() # Array[Nx20]
    def self.catalystNx20s()
        (NxTodos::items() + Waves::items())
            .map{|item|
                {
                    "announce" => "(#{item["mikuType"]}) #{PolyFunctions::genericDescriptionOrNull(item)}",
                    "unixtime" => item["unixtime"],
                    "item"     => item
                }
            }
    end

    # Search::nyxNx20s(fsroot) # Array[Nx20]
    def self.nyxNx20s(fsroot)
        Nx7::itemsFromFsRoot(fsroot)
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
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Search::catalystNx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Search::catalystNx20s()
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|i| i["announce"] })
                break if nx20.nil?
                PolyActions::landing(nx20["item"])
            }
        }
        nil
    end

    # Search::nyx(fsroot)
    def self.nyx(fsroot)
        loop {
            system('clear')
            puts "fsroot: #{fsroot}"
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Search::nyxNx20s(fsroot)
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Search::nyxNx20s(fsroot)
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|packet| PolyFunctions::toStringForListing(packet["item"]) })
                break if nx20.nil?
                PolyActions::landing(nx20["item"])
            }
        }
        nil
    end

    # Search::nyxFoxTerrier()
    def self.nyxFoxTerrier()
        loop {
            fsroot = Nx7::galaxyItems()
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            return nil if fragment == ""
            nx20 = Search::nyxNx20s(fsroot)
                        .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if nx20.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                nx20 = Search::nyxNx20s(fsroot)
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
