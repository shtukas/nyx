# encoding: UTF-8

class NxIceds

    # NxIceds::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxIced")
    end

    # NxIceds::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxIceds::toString(item)
    def self.toString(item)
        builder = lambda{
            "(iced) #{item["description"]}#{Cx::uuidToString(item["nx112"])}"
        }
        builder.call()
    end

    # NxIceds::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(iced) #{item["description"]}"
    end
end
