class PolyFunctions

    # PolyFunctions::toString(item)
    def self.toString(item)

        if item["mikuType"] == "LambdX1" then
            return "(lambda) #{item["announce"]}"
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxNode" then
            return NxNodes::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxBlock" then
            return NxBlocks::toString(item)
        end
        if item["mikuType"] == "NxTimeCommitment" then
            return NxTimeCommitments::toString(item)
        end
        if item["mikuType"] == "NxTimeDrop" then
            return item["description"]
        end
        if item["mikuType"] == "NxTodo" then
            return NxTodos::toString(item)
        end
        if item["mikuType"] == "NxTop" then
            return NxTops::toString(item)
        end
        if item["mikuType"] == "NxTriage" then
            return NxTriages::toString(item)
        end
        if item["mikuType"] == "TxStratosphere" then
            return TxStratospheres::toString(item)
        end
        if item["mikuType"] == "TxManualCountDown" then
            return "(countdown) #{item["description"]}: #{item["counter"]}"
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunctions::toStringForListing(item)
    def self.toStringForListing(item)
        if item["mikuType"] == "NxTimeCommitment" then
            return NxTimeCommitments::toStringWithDetails(item, true)
        end
        if item["mikuType"] == "NxTodo" then
            return item["description"]
        end
        PolyFunctions::toString(item)
    end

    # PolyFunctions::toStringForSearchListing(item)
    def self.toStringForSearchListing(item)
        if item["mikuType"] == "Wave" then
            return Waves::toStringForSearch(item)
        end
        PolyFunctions::toString(item)
    end
end
