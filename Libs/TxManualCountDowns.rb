
# encoding: UTF-8

class TxManualCountDowns

    # TxManualCountDowns::items()
    def self.items()
        ObjectStore2::objects("TxManualCountDowns")
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
            "counter"     => dailyTarget,
            "lastUpdatedUnixtime" => nil
        }
        ObjectStore2::commit("TxManualCountDowns", item)
        item
    end

    # TxManualCountDowns::commit(item)
    def self.commit(item)
        ObjectStore2::commit("TxManualCountDowns", item)
    end

    # Data

    # TxManualCountDowns::listingItems()
    def self.listingItems()
        TxManualCountDowns::items().each{|item|
            if item["date"] != CommonUtils::today() then
                item["date"] = CommonUtils::today()
                item["counter"] = item["dailyTarget"]
                ObjectStore2::commit("TxManualCountDowns", item)
            end
        }
        TxManualCountDowns::items()
            .select{|item| item["counter"] > 0 }
            .select{|item| item["lastUpdatedUnixtime"].nil? or (Time.new.to_i - item["lastUpdatedUnixtime"]) > 3600 }
    end

    # Ops

    # TxManualCountDowns::performUpdate(item)
    def self.performUpdate(item)
        puts "> #{item["description"]}"
        count = LucilleCore::askQuestionAnswerAsString("#{item["description"]}: done count: ").to_i
        item["counter"] = item["counter"] - count
        item["lastUpdatedUnixtime"] = Time.new.to_i
        puts JSON.pretty_generate(item)
        TxManualCountDowns::commit(item)
    end

    # TxManualCountDowns::access(item)
    def self.access(item)
        TxManualCountDowns::performUpdate(item)
    end
end
