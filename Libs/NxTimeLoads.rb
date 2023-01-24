
class NxTimeLoads

    # NxTimeLoads::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxTimeLoad/#{uuid}.json"
    end

    # NxTimeLoads::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTimeLoad")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxTimeLoads::commit(item)
    def self.commit(item)
        filepath = NxTimeLoads::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxTimeLoads::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxTimeLoads::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxTimeLoads::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTimeLoads::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxTimeLoads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        tcId = NxWTimeCommitments::interactivelySelectItem()["uuid"]
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTimeLoad",
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "hours"       => hours,
            "tcId"        => tcId
        }
        NxTimeLoads::commit(item)
        item
    end
    
    # NxTimeLoads::listingItems()
    def self.listingItems()
        NxTimeLoads::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # --------------------------------------------------
    # Data

    # NxTimeLoads::toString(item)
    def self.toString(item)
        pending = [item["hours"]-NxBalls::itemRealisedAndUnrealsedTimeInSeconds(item).to_f/3600, 0].max
        "(otc) (pending: #{"%5.2f" % (pending.round(2))}) #{item["description"]} (done: #{(NxBalls::itemRealisedAndUnrealsedTimeInSeconds(item).to_f/3600).round(2)} hours of #{item["hours"]})"
    end

    # NxTimeLoads::runningItems()
    def self.runningItems()
        NxTimeLoads::items()
            .select{|otc| NxBalls::getNxBallForItemOrNull(otc) }
    end

    # NxTimeLoads::itemLiveTimeThatShouldBeDoneTodayInHours(item)
    def self.itemLiveTimeThatShouldBeDoneTodayInHours(item)
        [item["hours"]*3600 - NxBalls::itemRealisedAndUnrealsedTimeInSeconds(item), 0].max
    end

    # NxTimeLoads::liveNumbers(otc)
    def self.liveNumbers(otc)
        pendingTimeTodayInSeconds = NxTimeLoads::itemLiveTimeThatShouldBeDoneTodayInHours(otc)
        {
            "timeThatShouldBeDoneTodayInHours" => pendingTimeTodayInSeconds.to_f/3600
        }
    end

    # NxTimeLoads::typeLiveTimeThatShouldBeDoneTodayInHours()
    def self.typeLiveTimeThatShouldBeDoneTodayInHours()
        NxTimeLoads::items()
            .map{|item| NxTimeLoads::itemLiveTimeThatShouldBeDoneTodayInHours(item) }
            .inject(0, :+)
    end
end