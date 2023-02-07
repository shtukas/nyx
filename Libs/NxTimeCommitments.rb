
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

    # NxTimeCommitments::toStringWithDetails(item)
    def self.toStringWithDetails(item)
        loadDoneInHours = BankCore::getValue(item["uuid"]).to_f/3600 + item["hours"]
        loadLeftInhours = item["hours"] - loadDoneInHours
        timePassedInDays = (Time.new.to_i - item["resetUnixtime"]).to_f/86400
        timeLeftInDays = 7 - timePassedInDays
        str1 = "(done #{loadDoneInHours.round(2).to_s.green} out of #{item["hours"]})"
        str2 = 
            if timeLeftInDays > 0 then
                average = loadLeftInhours.to_f/timeLeftInDays
                "(#{timeLeftInDays.round(2)} days before reset) (#{average.round(2)} hours/day)"
            else
                "(late by #{-timeLeftInDays.round(2)})"
            end
        "(tc) #{item["description"].ljust(8)} #{str1} #{str2}"
    end

    # NxTimeCommitments::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxTimeCommitments::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("time commitment", items, lambda{|item| NxTimeCommitments::toString(item) })
    end

    # NxTimeCommitments::differentialForListingPosition(item)
    def self.differentialForListingPosition(item)
        timeRatio       = (Time.new.to_i - item["resetUnixtime"]).to_f/(86400*5) # 5 days, ideally
        idealHoursDone  = item["hours"] * timeRatio
        actualHoursDone = BankCore::getValue(item["uuid"]).to_f/3600 + item["hours"]
        return 0 if actualHoursDone < idealHoursDone
        -(actualHoursDone - idealHoursDone).to_f/5
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
