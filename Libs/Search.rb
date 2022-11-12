
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

    # Search::nx7ToNx20(item)
    def self.nx7ToNx20(item)
        {
            "announce" => "(#{item["mikuType"]}) #{PolyFunctions::genericDescriptionOrNull(item)}",
            "unixtime" => item["unixtime"],
            "item"     => item
        }
    end

    # Search::nx20sCacheKey()
    def self.nx20sCacheKey()
        "c91404d2-1d28-431d-bfc4-17c5a06b2433:#{CommonUtils::today()}"
    end

    # Search::nyxNx20s() # Array[Nx20]
    def self.nyxNx20s()
        structure = XCache::getOrNull(Search::nx20sCacheKey())
        if structure then
            return JSON.parse(structure).values
        end

        useTheForce = lambda {
            Nx7::itemsEnumerator()
                .map{|item| Search::nx7ToNx20(item) }
        }

        puts "Search::nyxNx20s(): use the Force"
        array = useTheForce.call()
        structure = {}
        array.each{|nx20| structure[nx20["item"]["uuid"]] = nx20 }
        XCache::set(Search::nx20sCacheKey(), JSON.generate(structure))
        structure.values
    end

    # Search::commitNx7ToNx20Cache(item)
    def self.commitNx7ToNx20Cache(item)
        structure = XCache::getOrNull(Search::nx20sCacheKey())
        return if structure.nil?
        structure = JSON.parse(structure)
        nx20 = Search::nx7ToNx20(item)
        structure[item["uuid"]] = nx20
        XCache::set(Search::nx20sCacheKey(), JSON.generate(structure))
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

    # Search::nyx()
    def self.nyx()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Search::nyxNx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Search::nyxNx20s()
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|packet| PolyFunctions::toStringForListing(packet["item"]) })
                break if nx20.nil?
                item = nx20["item"]
                item = Nx7::itemOrNull(item["uuid"])
                PolyActions::landing(item)
            }
        }
        nil
    end

    # Search::nyxFoxTerrier()
    def self.nyxFoxTerrier()
        loop {
            fsroot = "/Users/pascal/Galaxy"
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            return nil if fragment == ""
            nx20 = Search::nyxNx20s()
                        .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if nx20.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                nx20 = Search::nyxNx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                            .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", nx20, lambda{|packet| PolyFunctions::toStringForListing(packet["item"]) })
                break if nx20.nil?
                system('clear')
                item = nx20["item"]
                item = Nx7::itemOrNull(item["uuid"])
                itemOpt = PolyFunctions::foxTerrierAtItem(item)
                return itemOpt if itemOpt
            }
        }
        nil
    end
end
