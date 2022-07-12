# encoding: UTF-8

class TxDateds

    # TxDateds::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxDated")
    end

    # TxDateds::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
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

        nx111 = Nx111::interactivelyCreateNewNx111OrNull()

        unixtime   = Time.new.to_i

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "TxDated",
            "description" => description,
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "nx111"       => nx111,
        }
        Librarian::commit(item)
        item
    end

    # TxDateds::interactivelyCreateNewTodayOrNull()
    def self.interactivelyCreateNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewNx111OrNull()

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "TxDated",
            "description" => description,
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "nx111"       => nx111,
        }
        Librarian::commit(item)
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
            Landing::implementsNx111Landing(item)
        }
    end

    # --------------------------------------------------
    # 

    # TxDateds::itemsForListing()
    def self.itemsForListing()
        TxDateds::items()
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
    end

    # --------------------------------------------------

    # TxDateds::nx20s()
    def self.nx20s()
        TxDateds::items().map{|item|
            {
                "announce" => TxDateds::toStringForSearch(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
