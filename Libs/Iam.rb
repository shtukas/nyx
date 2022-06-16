
# encoding: UTF-8

class Iam

    # Iam::nx111Types()
    def self.nx111Types()
        ["NxDataNode", "TxDated", "TxDated", "TxZero", "TxTodo", "Wave"]
    end

    # Iam::aggregationTypes()
    def self.aggregationTypes()
        ["NxCollection", "NxPerson", "NxTimeline"]
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
        targetType = Iam::interactivelyGetTransmutationTargetOrNull()
        return if targetType.nil?
        if Iam::nx111Types().include?(item["mikuType"]) and Iam::aggregationTypes().include?(targetType) then
            puts "You are moving from a data (Nx111) type to an aggregation type and therefore will lose the contents"
            return if !LucilleCore::askQuestionAnswerAsBoolean("Do you want to continue ?")
        end
        Transmutation::transmutation1(item, item["mikuType"], targetType)
    end

    # Iam::interactivelyGetTransmutationTargetOrNull()
    def self.interactivelyGetTransmutationTargetOrNull()
        options = Iam::nx111Types() + Iam::aggregationTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target type", options)
    end
end
