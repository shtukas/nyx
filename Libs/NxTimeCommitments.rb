
class NxTimeCommitments

    # --------------------------------------------
    # Makers

    # NxTimeCommitments::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours (weekly): ").to_f
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxTimeCommitment",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "resetTime"   => 0,
            "hours"       => hours
        }
        FileSystemCheck::fsck_NxTimeCommitment(item, true)
        TodoDatabase2::commitItem(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxTimeCommitments::toString(item)
    def self.toString(item)
        "(tc) #{item["description"]}"
    end

    # NxTimeCommitments::toStringWithDetails(item, shouldFormat)
    def self.toStringWithDetails(item, shouldFormat)
        "(tc) (hours: #{item["hours"]}) #{item["description"]}"
    end

    # NxTimeCommitments::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = Database2Data::itemsForMikuType("NxTimeCommitment")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("time commitment", items, lambda{|item| NxTimeCommitments::toString(item) })
    end
end
