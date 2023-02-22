# encoding: UTF-8

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        Waves::items()
    end
end

class CatalystSearch

    # CatalystSearch::nx20s() # Array[Nx20]
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

    # CatalystSearch::run()
    def self.run()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = CatalystSearch::nx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = CatalystSearch::nx20s()
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