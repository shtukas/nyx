
class NxTops

    # --------------------------------------------------
    # Makers

    # NxTops::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTop",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description
        }
        TodoDatabase2::commit_item(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTops::toString(item)
    def self.toString(item)
        "(top) #{item["description"]}"
    end

    # NxTops::listingItems()
    def self.listingItems()
        TodoDatabase2::itemsForMikuType("NxTop")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end
end