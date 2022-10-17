
# encoding: UTF-8

class TxManualCountDowns

    # Basic IO

    # TxManualCountDowns::items()
    def self.items()
        PhageAgentMikutypes::mikuTypeToObjects("TxManualCountDown")
    end

    # TxManualCountDowns::commit(item)
    def self.commit(item)
        Phage::commit(item)
    end

    # TxManualCountDowns::destroy(uuid)
    def self.destroy(uuid)
        PhageRefactoring::destroy(uuid)
    end

    # Makers

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
        TxManualCountDowns::commit(item)
        item
    end

    # Data

    # TxManualCountDowns::listingItems()
    def self.listingItems()
        TxManualCountDowns::items().each{|item|
            if item["date"] != CommonUtils::today() then
                item["date"] = CommonUtils::today()
                item["counter"] = item["dailyTarget"]
                TxManualCountDowns::commit(item)
            end
        }
        TxManualCountDowns::items()
            .select{|item| item["counter"] > 0 }
    end

end
