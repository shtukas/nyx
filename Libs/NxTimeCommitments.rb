
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
        "(timecommitment) #{item["description"]}"
    end

    # NxTimeCommitments::toStringWithDetails(item, shouldFormat)
    def self.toStringWithDetails(item, shouldFormat)
        "(timecommitment) (hours: #{item["hours"]}) #{item["description"]}"
    end

    # --------------------------------------------
    # Ops

    # NxTimeCommitments::probe(timecommitment)
    def self.probe(timecommitment)
        loop {
            puts NxTimeCommitments::toStringWithDetails(timecommitment, false)
            actions = ["do not show until", "set hours", "expose"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(timecommitment["uuid"], unixtime)
            end
            if action == "set hours" then
                timecommitment["hours"] = LucilleCore::askQuestionAnswerAsString("hours (weekly): ").to_f
                TodoDatabase2::commitItem(timecommitment)
            end
            if action == "expose" then
                puts JSON.pretty_generate(timecommitment)
                LucilleCore::pressEnterToContinue()
            end
        }
    end
end
