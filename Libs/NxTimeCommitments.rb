
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
        hoursDone = BankCore::getValue(item["uuid"]).to_f/3600 + item["hours"]
        hoursLeft = item["hours"] - hoursDone
        timeLeftInDays = 7 - (Time.new.to_i - item["resetUnixtime"]).to_f/86400
        str = 
            if hoursLeft <= 0 then
                "(all #{item["hours"]} done, acutally done: #{hoursDone.round(2)}, #{timeLeftInDays.round(2)} days before reset)"
            else
                if timeLeftInDays > 0 then
                    "(done #{hoursDone.round(2).to_s.green} out of #{item["hours"]}, #{timeLeftInDays.round(2)} days before reset)"
                else
                    "(done #{hoursDone.round(2).to_s.green} out of #{item["hours"]}, and your are late by #{-timeLeftInDays.round(2)})"
                end
            end

        "(-tc-) #{item["description"]} #{str}"
    end

    # NxTimeCommitments::isWithinIdealProgression(item)
    def self.isWithinIdealProgression(item)
        timeInSequenceInDays = (Time.new.to_i - item["resetUnixtime"]).to_f/86400
        ratioInSequence = timeInSequenceInDays.to_f/5 # We should be using 7 here , but we are going to use 5 to give us 2 days break
        idealBankValueInHours = -item["hours"] + ratioInSequence*item["hours"]
        BankCore::getValue(item["uuid"]).to_f/3600 > idealBankValueInHours
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
