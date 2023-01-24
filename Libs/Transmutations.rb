
class Transmutations

    # Transmutations::transmute(item, sourceType, targetType)
    def self.transmute(item, sourceType, targetType)

    end

    # Transmutations::interactivelySelectTargetTypeOrNull(item)
    def self.interactivelySelectTargetTypeOrNull(item)
        nil
    end

    def self.transmuting(item)
        targetType = Transmutations::interactivelySelectTargetTypeOrNull(item)
        return if targetType.nil?
        Transmutations::transmute(item, item["mikuType"], targetType)
    end

end
