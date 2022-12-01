
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
                PolyActions::probe(item)
            }
        }
        nil
    end
end

class SearchNyx

    # SearchNyx::nx7ToNx20(item)
    def self.nx7ToNx20(item)
        {
            "announce" => "(#{item["mikuType"]}) #{PolyFunctions::genericDescription(item)}",
            "unixtime" => item["unixtime"],
            "item"     => item
        }
    end

    # SearchNyx::nx20sCacheKey()
    def self.nx20sCacheKey()
        "c91404d2-1d28-431d-bfc4-17c5a06b2433:#{CommonUtils::today()}"
    end

    # SearchNyx::nyxNx20s() # Array[Nx20]
    def self.nyxNx20s()
        structure = XCache::getOrNull(SearchNyx::nx20sCacheKey())
        if structure then
            return JSON.parse(structure).values
        end

        useTheForce = lambda {
            Nx7::itemsEnumerator()
                .map{|item| SearchNyx::nx7ToNx20(item) }
        }

        puts "SearchNyx::nyxNx20s(): use the Force"
        array = useTheForce.call()
        structure = {}
        array.each{|nx20| structure[nx20["item"]["uuid"]] = nx20 }
        XCache::set(SearchNyx::nx20sCacheKey(), JSON.generate(structure))
        structure.values
    end

    # SearchNyx::commitNx7ToNx20Cache(item)
    def self.commitNx7ToNx20Cache(item)
        structure = XCache::getOrNull(SearchNyx::nx20sCacheKey())
        return if structure.nil?
        structure = JSON.parse(structure)
        nx20 = SearchNyx::nx7ToNx20(item)
        structure[item["uuid"]] = nx20
        XCache::set(SearchNyx::nx20sCacheKey(), JSON.generate(structure))
    end

    # SearchNyx::deleteNx7FromNx20Cache(uuid)
    def self.deleteNx7FromNx20Cache(uuid)
        structure = XCache::getOrNull(SearchNyx::nx20sCacheKey())
        return if structure.nil?
        structure = JSON.parse(structure)
        structure.delete(uuid)
        XCache::set(SearchNyx::nx20sCacheKey(), JSON.generate(structure))
    end

    # SearchNyx::nyx()
    def self.nyx()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = SearchNyx::nyxNx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = SearchNyx::nyxNx20s()
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|packet| PolyFunctions::toString(packet["item"]) })
                break if nx20.nil?
                item = nx20["item"]
                item = Nx7::itemOrNull(item["uuid"])
                PolyActions::probe(item)
            }
        }
        nil
    end

    # SearchNyx::nyxFoxTerrier()
    def self.nyxFoxTerrier()
        loop {
            fsroot = "/Users/pascal/Galaxy"
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            return nil if fragment == ""
            nx20 = SearchNyx::nyxNx20s()
                        .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if nx20.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                nx20 = SearchNyx::nyxNx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                            .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", nx20, lambda{|packet| PolyFunctions::toString(packet["item"]) })
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
