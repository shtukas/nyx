
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
            "field3"      => hours
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
        "(tc) (hours: #{item["field3"]}) #{item["description"]}"
    end

    # NxTimeCommitments::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = Database2Data::itemsForMikuType("NxTimeCommitment")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("time commitment", items, lambda{|item| NxTimeCommitments::toString(item) })
    end

    # NxTimeCommitments::toStringForListing(store, item)
    def self.toStringForListing(store, item)
        capsule = Database2Data::itemsForMikuType("NxTimeCapsule")
        hours = capsule.select{|drop| drop["field10"] == item["uuid"] }.map{|drop| drop["field1"] }.inject(0, :+)
        sinceResetInSeconds = Time.new.to_i - item["resetTime"]
        sinceResetInDays = sinceResetInSeconds.to_f/86400
        str1 =
            if sinceResetInDays < 7 then
                daysLeft = 7 - sinceResetInDays
                " (#{"%4.2f" % daysLeft} days left, #{"%4.2f" % (hours.to_f/daysLeft)} hours per day)"
            else
                " (late by #{(sinceResetInDays - 7).round(2)} days)"
            end
        "(#{store.prefixString()}) #{item["description"].ljust(10)} (left: #{("%5.2f" % hours).to_s.green} hours, out of #{"%5.2f" % item["field3"]})#{str1}"
    end

    # NxTimeCommitments::uuidToDescription(uuid)
    def self.uuidToDescription(uuid)
        description = XCache::getOrNull("364347df-1724-47d6-928c-c5a5da999015:#{CommonUtils::today()}:#{uuid}")
        return description if description
        description = Database2Data::itemsForMikuType("NxTimeCommitment").select{|tc| tc["uuid"] == uuid }.map{|tc| tc["description"] }.first
        if description then
            XCache::set("364347df-1724-47d6-928c-c5a5da999015:#{CommonUtils::today()}:#{uuid}", description)
        end
        description
    end
end
