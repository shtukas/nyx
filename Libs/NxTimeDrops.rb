
class NxTimeDrops

    # --------------------------------------------------
    # Makers

    # NxTimeDrops::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        tcId = NxTimeFibers::interactivelySelectItem()["uuid"]
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTimeDrop",
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "hours"       => hours,
            "tcId"        => tcId
        }
        TodoDatabase2::commit_item(item)
        item
    end
    
    # NxTimeDrops::listingItems()
    def self.listingItems()
        TodoDatabase2::itemsForMikuType("NxTimeDrop")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # --------------------------------------------------
    # Data

    # NxTimeDrops::toString(item)
    def self.toString(item)
        pending = [item["hours"]-NxBalls::itemRealisedAndUnrealsedTimeInSeconds(item).to_f/3600, 0].max
        "(otc) (pending: #{"%5.2f" % (pending.round(2))}) #{item["description"]} (done: #{(NxBalls::itemRealisedAndUnrealsedTimeInSeconds(item).to_f/3600).round(2)} hours of #{item["hours"]})"
    end

    # NxTimeDrops::runningItems()
    def self.runningItems()
        TodoDatabase2::itemsForMikuType("NxTimeDrop")
            .select{|otc| NxBalls::getNxBallForItemOrNull(otc) }
    end

    # NxTimeDrops::liveNumbers(otc)
    def self.liveNumbers(otc)
        timeInHours = [item["hours"]*3600 - NxBalls::itemRealisedAndUnrealsedTimeInSeconds(item), 0].max
        {
            "pendingTimeTodayInHoursLive" => timeInHours.to_f/3600
        }
    end

    # NxTimeDrops::allPendingTimeTodayInHoursLive()
    def self.allPendingTimeTodayInHoursLive()
        TodoDatabase2::itemsForMikuType("NxTimeDrop")
            .map{|item| NxTimeDrops::liveNumbers(item)["pendingTimeTodayInHoursLive"] }
            .inject(0, :+)
    end
end