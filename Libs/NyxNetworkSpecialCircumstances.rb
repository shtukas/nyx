# encoding: UTF-8

class NyxNetworkSpecialCircumstances

    # NyxNetworkSpecialCircumstances::transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
    def self.transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
        if item["nx111"]["type"] != "aion-point" then
            puts "I can only do that with aion-points"
            LucilleCore::pressEnterToContinue()
            return
        end
        item2 = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxDataNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Genesis",
            "nx111"       => item["nx111"].clone
        }
        puts JSON.pretty_generate(item2)
        Librarian::commit(item2)
        NxArrow::issue(item["uuid"], item2["uuid"])
        item["mikuType"] = "NxNavigation"
        puts JSON.pretty_generate(item)
        Librarian::commit(item)
        puts "Operation completed"
        LucilleCore::pressEnterToContinue()
    end
end
