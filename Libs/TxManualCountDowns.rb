
# encoding: UTF-8

class TxManualCountDowns

    # TxManualCountDowns::uuids()
    def self.uuids()
        uuids = XCache::getOrNull("3b38d7db-2057-43b0-b1a8-59017d581e98")
        return [] if uuids.nil?
        JSON.parse(uuids)
    end

    # TxManualCountDowns::setuuids(uuids)
    def self.setuuids(uuids)
        XCache::set("3b38d7db-2057-43b0-b1a8-59017d581e98", JSON.generate(uuids))
    end

    # TxManualCountDowns::issueNewOrNull()
    def self.issueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        dailyTarget = LucilleCore::askQuestionAnswerAsString("daily target (empty to abort): ")
        return nil if dailyTarget == ""
        dailyTarget = dailyTarget.to_i
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "TxManualCountDown",
            "description" => description,
            "dailyTarget" => dailyTarget,
            "date"        => CommonUtils::today(),
            "counter"     => dailyTarget
        }
        TxManualCountDowns::pushItemUpdate(item)
        item
    end

    # TxManualCountDowns::destroy(itemuuid)
    def self.destroy(itemuuid)
        uuids = TxManualCountDowns::uuids()
        TxManualCountDowns::setuuids(uuids - [itemuuid])
    end

    # TxManualCountDowns::items
    def self.items
        TxManualCountDowns::uuids()
            .map{|itemuuid| XCache::getOrNull(itemuuid) }
            .compact
            .map{|item| JSON.parse(item) }
    end

    # TxManualCountDowns::listingItems()
    def self.listingItems()
        TxManualCountDowns::items.each{|item|
            if item["date"] != CommonUtils::today() then
                item["date"] = CommonUtils::today()
                item["counter"] = item["dailyTarget"]
                XCache::set(item["uuid"], JSON.generate(item))
                SystemEvents::broadcast(item)
            end
        }
        TxManualCountDowns::items
            .select{|item| item["counter"] > 0 }
    end

    # TxManualCountDowns::pushItemUpdate(item)
    def self.pushItemUpdate(item)
        XCache::set(item["uuid"], JSON.generate(item))
        uuids = TxManualCountDowns::uuids()
        uuids = (uuids + [item["uuid"]]).uniq
        TxManualCountDowns::setuuids(uuids)
        SystemEvents::broadcast(item)
    end

end
