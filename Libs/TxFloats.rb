# encoding: UTF-8

class TxFloats

    # --------------------------------------------------
    # Makers

    # TxFloats::interactivelyIssueOrNull()
    def self.interactivelyIssueOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "TxFloat",
            "unixtime"    => Time.new.to_i,
            "description" => description
        }
        ItemsManager::commit("TxFloat", item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxFloats::toString(item)
    def self.toString(item)
        "(float) #{item["description"]}"
    end

    # TxFloats::listingItems()
    def self.listingItems()
        ItemsManager::items("TxFloat")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end
end
