
class ItemToTimeCommitmentMapping

    # ItemToTimeCommitmentMapping::set(uuid, tcuuid)
    def self.set(uuid, tcuuid)
        puts "ItemToTimeCommitmentMapping::set(#{uuid}, #{tcuuid})"
        Lookups::commit("ItemToTimeCommitmentMapping", uuid, tcuuid)
    end

    # ItemToTimeCommitmentMapping::getOrNull(item)
    def self.getOrNull(item)
        if item["mikuType"] == "NxBoardFirstItem" then
            item = item["todo"]
        end
        Lookups::getValueOrNull("ItemToTimeCommitmentMapping", item["uuid"])
    end

    # ItemToTimeCommitmentMapping::toStringSuffix(item)
    def self.toStringSuffix(item)
        if item["mikuType"] == "NxBoardFirstItem" then
            item = item["todo"]
        end
        tcuuid = ItemToTimeCommitmentMapping::getOrNull(item)
        return "" if tcuuid.nil?
        tc = NxTimeCommitments::getItemOfNull(tcuuid)
        return "" if tc.nil?
        " (tc: #{tc["description"]})"
    end

    # ItemToTimeCommitmentMapping::interactiveProposalToSetMapping(item)
    def self.interactiveProposalToSetMapping(item)
        if item["mikuType"] == "NxBoardFirstItem" then
            item = item["todo"]
        end
        tc = NxTimeCommitments::interactivelySelectOneOrNull()
        return if tc.nil?
        ItemToTimeCommitmentMapping::set(item["uuid"], tc["uuid"])
    end
end
