
class NxTimeDrops

    # NxTimeDrops::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxTimeDrop/#{uuid}.json"
    end

    # NxTimeDrops::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTimeDrop")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxTimeDrops::commit(item)
    def self.commit(item)
        filepath = NxTimeDrops::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxTimeDrops::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxTimeDrops::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxTimeDrops::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTimeDrops::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

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
        NxTimeDrops::commit(item)
        item
    end
    
    # NxTimeDrops::listingItems()
    def self.listingItems()
        NxTimeDrops::items()
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
        NxTimeDrops::items()
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
        NxTimeDrops::items()
            .map{|item| NxTimeDrops::liveNumbers(item)["pendingTimeTodayInHoursLive"] }
            .inject(0, :+)
    end
end