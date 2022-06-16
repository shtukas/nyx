# encoding: UTF-8

class NyxNetworkSpecialCircumstances

    # NyxNetworkSpecialCircumstances::transmuteToAggregationNodeAndPutContentsIntoGenesisOrNothing(item)
    def self.transmuteToAggregationNodeAndPutContentsIntoGenesisOrNothing(item)
        return if !Iam::nx111Types().include?(item["mikuType"])
        targetType = Iam::interactivelyGetTransmutationTargetOrNull()
        return if targetType.nil?

        if !Transmutation::transmutation1(item, item["mikuType"], targetType, true) then
            puts "Simulation shows that I do not yet know how to transmute #{item["mikuType"]} to #{targetType}"
            LucilleCore::pressEnterToContinue()
            return
        end

        item2 = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxDataNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "#{item["description"]} Genesis",
            "nx111"       => item["nx111"].clone
        }
        puts JSON.pretty_generate(item2)
        Librarian::commit(item2)
        NxArrow::issue(item["uuid"], item2["uuid"])

        Transmutation::transmutation1(item, item["mikuType"], targetType)
    end
end
