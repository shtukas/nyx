
class NxOTimeCommitments

    # NxOTimeCommitments::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxOTimeCommitment/#{uuid}.json"
    end

    # NxOTimeCommitments::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxOTimeCommitment")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| 
                item = JSON.parse(IO.read(filepath)) 
                if NxOTimeCommitments::itemPendingTimeInSeconds(item) <= 0 then
                    FileUtils.rm(filepath)
                    nil
                else
                    item
                end
            }
    end

    # NxOTimeCommitments::commit(item)
    def self.commit(item)
        filepath = NxOTimeCommitments::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxOTimeCommitments::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxOTimeCommitments::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxOTimeCommitments::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxOTimeCommitments::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxOTimeCommitments::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        tcId = NxWTimeCommitments::interactivelySelectItem()["uuid"]
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOTimeCommitment",
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "hours"       => hours,
            "tcId"        => tcId
        }
        NxOTimeCommitments::commit(item)
        item
    end
    
    # NxOTimeCommitments::listingItems()
    def self.listingItems()
        NxOTimeCommitments::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # --------------------------------------------------
    # Data

    # NxOTimeCommitments::toString(item)
    def self.toString(item)
        "(otc) (pending: #{"%5.2f" % (item["hours"]-NxBalls::itemRealisedAndUnrealsedTimeInSeconds(item))}) #{item["description"]} (done: #{NxBalls::itemRealisedAndUnrealsedTimeInSeconds(item)} hours of #{item["hours"]})"
    end

    # NxOTimeCommitments::itemPendingTimeInSeconds(item)
    def self.itemPendingTimeInSeconds(item)
        item["hours"]*3600 - NxBalls::itemRealisedAndUnrealsedTimeInSeconds(item)
    end

    # NxOTimeCommitments::pendingTimeInSeconds()
    def self.pendingTimeInSeconds()
        NxOTimeCommitments::items()
            .map{|item| NxOTimeCommitments::itemPendingTimeInSeconds(item) }
            .inject(0, :+)
    end
end