# encoding: UTF-8

class TxStratospheres

    # --------------------------------------------------
    # Makers

    # TxStratospheres::interactivelyIssueOrNull()
    def self.interactivelyIssueOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "TxStratosphere",
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "ordinal"     => ordinal
        }
        TodoDatabase2::commitItem(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxStratospheres::toString(item)
    def self.toString(item)
        "(strat) (#{"%5.2f" % item["ordinal"]}) #{item["description"]}"
    end

    # TxStratospheres::listingItems()
    def self.listingItems()
        Database2Data::itemsForMikuType("TxStratosphere")
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
    end
end
