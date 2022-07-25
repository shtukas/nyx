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

        uuid2 = SecureRandom.uuid
        Fx18Attributes::setAttribute2(uuid, "uuid",        uuid2)
        Fx18Attributes::setAttribute2(uuid, "mikuType",    "NxDataNode")
        Fx18Attributes::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setAttribute2(uuid, "description", "#{item["description"]} Genesis")
        Fx18Attributes::setAttribute2(uuid, "nx111",       JSON.generate(item["nx111"]))
        NxLink::issue(item["uuid"], uuid2)
        Transmutation::transmutation1(item, item["mikuType"], targetType)
    end
end
