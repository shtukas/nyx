# encoding: UTF-8

class TxDateds

    # TxDateds::items()
    def self.items()
        TheIndex::mikuTypeToItems("TxDated")
    end

    # TxDateds::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObject(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxDateds::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        datetime = CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode()
        return nil if datetime.nil?
        uuid = SecureRandom.uuid
        cx = Cx::interactivelyCreateNewCxForOwnerOrNull(uuid)
        unixtime   = Time.new.to_i
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "TxDated")
        DxF1::setAttribute2(uuid, "unixtime",    unixtime)
        DxF1::setAttribute2(uuid, "datetime",    datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx112",       cx ? cx["uuid"] : nil)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 06f11b6f-7d31-411b-b3bf-7b1115a756a9) How did that happen ? 🤨"
        end
        item
    end

    # TxDateds::interactivelyCreateNewTodayOrNull()
    def self.interactivelyCreateNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        cx = Cx::interactivelyCreateNewCxForOwnerOrNull(uuid)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "TxDated")
        DxF1::setAttribute2(uuid, "unixtime",    unixtime)
        DxF1::setAttribute2(uuid, "datetime",    datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx112",       cx ? cx["uuid"] : nil)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 69486f48-3748-4c73-b604-a7edad98871d) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # toString

    # TxDateds::toString(item)
    def self.toString(item)
        "(ondate) [#{item["datetime"][0, 10]}] #{item["description"]}#{Cx::uuidToString(item["nx112"])} 🗓"
    end

    # TxDateds::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(ondate) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxDateds::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxDateds::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("dated", items, lambda{|item| TxDateds::toString(item) })
            break if item.nil?
            PolyPrograms::itemLanding(item)
        }
    end

    # --------------------------------------------------
    # 

    # TxDateds::listingItems()
    def self.listingItems()
        TxDateds::items()
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
    end
end
