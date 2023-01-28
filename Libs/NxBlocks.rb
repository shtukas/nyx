# encoding: UTF-8

class NxBlocks

    # --------------------------------------------------
    # Makers

    # NxBlocks::interactivelyDecideOrdinal()
    def self.interactivelyDecideOrdinal()
        TodoDatabase2::itemsForMikuType("NxBlock")
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .first(20)
            .each{|item| 
                puts NxBlocks::toString(item)
            }
        puts ""
        LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
    end

    # NxBlocks::interactivelyIssueOrNull()
    def self.interactivelyIssueOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ordinal = NxBlocks::interactivelyDecideOrdinal()
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBlock",
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "ordinal"     => ordinal
        }
        TodoDatabase2::commit_item(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxBlocks::toString(item)
    def self.toString(item)
        "(block) (#{"%5.2f" % item["ordinal"]}) #{item["description"]}"
    end

    # NxBlocks::listingItems(cardinal)
    def self.listingItems(cardinal)
        TodoDatabase2::itemsForMikuType("NxBlock")
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .take(cardinal)
            .select{|item| BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) < 0.5 }
    end
end
