# encoding: UTF-8

class TxDateds

    # TxDateds::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "TxDated"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "description"),
            "nx111"       => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "nx111"),
        }
    end

    # TxDateds::items()
    def self.items()
        Lookup1::mikuTypeToItems("TxDated")
    end

    # TxDateds::destroy(uuid)
    def self.destroy(uuid)
        Fx18s::deleteObject(uuid)
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
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        unixtime   = Time.new.to_i
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "mikuType",    "TxDated")
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "unixtime",    unixtime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "datetime",    datetime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "description", description)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        Fx18s::broadcastObjectEvents(uuid)
        item = TxDateds::objectuuidToItemOrNull(uuid)
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
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "mikuType",    "TxDated")
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "unixtime",    unixtime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "datetime",    datetime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "description", description)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        Fx18s::broadcastObjectEvents(uuid)
        item = TxDateds::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: 69486f48-3748-4c73-b604-a7edad98871d) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # toString

    # TxDateds::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(ondate) [#{item["datetime"][0, 10]}] #{item["description"]}#{nx111String} 🗓"
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
            Landing::implementsNx111Landing(item, isSearchAndSelect = false)
        }
    end

    # --------------------------------------------------
    # 

    # TxDateds::section2()
    def self.section2()
        TxDateds::items()
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
    end
end
