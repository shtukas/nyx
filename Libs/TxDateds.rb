# encoding: UTF-8

class TxDateds

    # TxDateds::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "TxDated"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "nx111"       => Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111")),
        }
    end

    # TxDateds::items()
    def self.items()
        Lookup1::mikuTypeToItems("TxDated")
    end

    # TxDateds::destroy(uuid)
    def self.destroy(uuid)
        Fx18::deleteObject(uuid)
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
        Fx18Attributes::set2(uuid, "uuid",        uuid)
        Fx18Attributes::set2(uuid, "mikuType",    "TxDated")
        Fx18Attributes::set2(uuid, "unixtime",    unixtime)
        Fx18Attributes::set2(uuid, "datetime",    datetime)
        Fx18Attributes::set2(uuid, "description", description)
        Fx18Attributes::set2(uuid, "nx111",       JSON.generate(nx111))
        FileSystemCheck::fsckObject(uuid)
        uuid
    end

    # TxDateds::interactivelyCreateNewTodayOrNull()
    def self.interactivelyCreateNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18Attributes::set2(uuid, "uuid",        uuid)
        Fx18Attributes::set2(uuid, "mikuType",    "TxDated")
        Fx18Attributes::set2(uuid, "unixtime",    unixtime)
        Fx18Attributes::set2(uuid, "datetime",    datetime)
        Fx18Attributes::set2(uuid, "description", description)
        Fx18Attributes::set2(uuid, "nx111",       JSON.generate(nx111))
        FileSystemCheck::fsckObject(uuid)
        uuid
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
            .map{|item|
                {
                    "item" => item,
                    "toString" => TxDateds::toString(item),
                    "metric"   => 0.8 + Catalyst::idToSmallShift(item["uuid"])
                }
            }
    end
end
