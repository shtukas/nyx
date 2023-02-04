
class NxTimeCommitments

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
            "field10"     => uuid,
        }
        FileSystemCheck::fsck_NxTimeCommitment(item, true)
        ObjectStore1::commitItem(item)
        item
    end

    # NxTimeCommitments::items()
    def self.items()
        Engine::itemsForMikuType("NxTimeCommitment")
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
        items = Engine::itemsForMikuType("NxTimeCommitment")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("time commitment", items, lambda{|item| NxTimeCommitments::toString(item) })
    end

    # NxTimeCommitments::toStringForListing(item)
    def self.toStringForListing(item)
        capsule = Engine::itemsForMikuType("NxTimeCapsule")
        hours = capsule.select{|drop| drop["field10"] == item["uuid"] }.map{|drop| drop["field1"] }.inject(0, :+)
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

    # NxTimeCommitments::uuidToDescription(uuid)
    def self.uuidToDescription(uuid)
        description = XCache::getOrNull("364347df-1724-47d6-928c-c5a5da999015:#{CommonUtils::today()}:#{uuid}")
        return description if description
        description = Engine::itemsForMikuType("NxTimeCommitment").select{|tc| tc["uuid"] == uuid }.map{|tc| tc["description"] }.first
        if description then
            XCache::set("364347df-1724-47d6-928c-c5a5da999015:#{CommonUtils::today()}:#{uuid}", description)
        end
        description
    end
end
