
class NxTimeCommitments

    # NxTimeCommitments::items()
    def self.items()
        ObjectStore2::objects("NxTimeCommitments")
    end

    # NxTimeCommitments::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        ObjectStore2::getOrNull("NxTimeCommitments", uuid)
    end

    # --------------------------------------------
    # Makers

    # NxTimeCommitments::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours (weekly): ").to_f
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTimeCommitment",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "resetTime"   => 0,
            "field3"      => hours,
        }
        FileSystemCheck::fsck_NxTimeCommitment(item, true)
        ObjectStore2::commit("NxTimeCommitments", item)
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
        "(tc) (hours: #{item["field3"]}) #{item["description"]}"
    end

    # NxTimeCommitments::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxTimeCommitments::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("time commitment", items, lambda{|item| NxTimeCommitments::toString(item) })
    end

    # NxTimeCommitments::toStringForListing(item)
    def self.toStringForListing(item)
        hours = BankCore::getValue(item["uuid"]).to_f/3600
        sinceResetInSeconds = Time.new.to_i - item["resetTime"]
        sinceResetInDays = sinceResetInSeconds.to_f/86400
        str1 =
            if sinceResetInDays < 7 then
                daysLeft = 7 - sinceResetInDays
                if daysLeft > 1 then
                    " (#{"%4.2f" % daysLeft} days left, #{"%5.2f" % ([hours, 0].max.to_f/daysLeft)} hours per day)"
                else
                    " (#{"%4.2f" % daysLeft} days left)"
                end
                
            else
                " (late by #{(sinceResetInDays - 7).round(2)} days)"
            end
        "#{item["description"].ljust(10)} (left: #{("%5.2f" % hours).to_s.green} hours, out of #{"%5.2f" % item["field3"]})#{str1}"
    end
end
