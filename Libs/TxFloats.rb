# encoding: UTF-8

class TxFloats

    # TxFloats::items()
    def self.items()
        TheIndex::mikuTypeToItems("TxFloat")
    end

    # TxFloats::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxFloats::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        cx = Cx::interactivelyCreateNewCxForOwnerOrNull(uuid)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "TxFloat")
        DxF1::setAttribute2(uuid, "unixtime",    unixtime)
        DxF1::setAttribute2(uuid, "datetime",    datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx112",       cx ? cx["uuid"] : nil)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: b63ae301-b0a1-47da-a445-8c53a457d0fe) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # Data

    # TxFloats::toString(item)
    def self.toString(item)
        "(float) #{item["description"]}#{Cx::uuidToString(item["nx112"])}"
    end

    # TxFloats::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(float) #{item["description"]}"
    end

    # TxFloats::listingItems()
    def self.listingItems()
        TxFloats::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # --------------------------------------------------
    # Operations

    # TxFloats::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxFloats::items()
                        .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("float", items, lambda{|item| PolyFunctions::toString(item) })
            return if item.nil?
            PolyFunctions::landing(item, false)
        }
    end
end
