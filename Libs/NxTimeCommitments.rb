
class NxTimeCommitments

    # NxTimeCommitments::items()
    def self.items()
        ObjectStore2::objects("NxTimeCommitments")
    end

    # NxTimeCommitments::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        ObjectStore2::getOrNull("NxTimeCommitments", uuid)
    end

    # NxTimeCommitments::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxTimeCommitments", item)
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
            "hours"       => hours,
            "resetUnixtime"   => 0,
        }
        FileSystemCheck::fsck_MikuTypedItem(item, true)
        NxTimeCommitments::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxTimeCommitments::toString(item)
    def self.toString(item)
        "(tc) #{item["description"]}"
    end

    # NxTimeCommitments::toStringForListing(item)
    def self.toStringForListing(item)
        hours = BankCore::getValue(item["uuid"]).to_f/3600
        "(-tc-) #{item["description"]} (left: #{("%5.2f" % (-hours)).to_s.green} hours, out of #{"%5.2f" % item["hours"]})"
    end

    # NxTimeCommitments::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxTimeCommitments::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("time commitment", items, lambda{|item| NxTimeCommitments::toString(item) })
    end

    # ----------------------------------------------------------------
    # Ops

    # NxTimeCommitments::timeManagement()
    def self.timeManagement()
        NxTimeCommitments::items().each{|item|
            puts item
            if (Time.new.to_i - item["resetUnixtime"]) >= 86400*7 then
                # Time for a reset
                puts "NxTimeCommitments, resetting #{item["description"]}"
                BankCore::put(item["uuid"], -item["hours"]*3600)
                item["resetUnixtime"] = Time.new.to_f
                NxTimeCommitments::commit(item)
            end
        }
    end

end
