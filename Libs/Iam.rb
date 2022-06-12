
# encoding: UTF-8

class Iam

    # Iam::nx111Types()
    def self.nx111Types()
        ["NxDataNode", "TxDated", "TxDated", "TxPlus", "TxTodo", "Wave"]
    end

    # Iam::aggregationTypes()
    def self.aggregationTypes()
        ["NxCollection", "NxNavigation", "NxPerson", "NxTimeline"]
    end

    # Iam::implementsNx111(item)
    def self.implementsNx111(item)
        Iam::nx111Types().include?(item["mikuType"])
    end

    # Iam::isNetworkAggregation(item)
    def self.isNetworkAggregation(item)
        Iam::aggregationTypes().include?(item["mikuType"])
    end

    # Iam::processItem(item)
    def self.processItem(item)
        if Iam::implementsNx111(item) then
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["convert to network aggregation node"])
            return if action.nil?
            if action == "convert to network aggregation node" then
                if LucilleCore::askQuestionAnswerAsBoolean("Can we discard the existing data payload ? ") then
                    type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", Iam::aggregationTypes())
                    return if type.nil?
                    item["mikuType"] = type
                    Librarian::commit(item)
                end
                return
            end
            raise "(error: 20b33796-501e-4f02-9724-756e89a5f18b)"
        end
    end
end
