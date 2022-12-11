
# encoding: UTF-8

class TxManualCountDowns

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
        ItemsManager::commit("TxManualCountDown", item)
        item
    end

    # Data

    # TxManualCountDowns::listingItems()
    def self.listingItems()
        ItemsManager::items("TxManualCountDown").each{|item|
            if item["date"] != CommonUtils::today() then
                item["date"] = CommonUtils::today()
                item["counter"] = item["dailyTarget"]
                ItemsManager::commit("TxManualCountDown", item)
            end
        }
        ItemsManager::items("TxManualCountDown")
            .select{|item| item["counter"] > 0 }
            .select{|item| item["lastUpdatedUnixtime"].nil? or (Time.new.to_i - item["lastUpdatedUnixtime"]) > 3600 }
    end

end
