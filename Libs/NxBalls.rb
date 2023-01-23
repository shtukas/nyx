# encoding: UTF-8

class NxBalls

    # NxBalls::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxBall/#{uuid}.json"
    end

    # NxBalls::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxBall")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxBalls::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxBalls::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxBalls::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxBalls::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxBalls::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxBalls::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxBalls::issue(accounts, linkeditemuuid = nil, sequenceStart = nil, isActive = true)
    def self.issue(accounts, linkeditemuuid = nil, sequenceStart = nil, isActive = true)
        uuid  = SecureRandom.uuid
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxBall",
            "unixtime" => Time.new.to_i,
            "isActive" => isActive,
            "accounts" => accounts,
            "itemuuid" => linkeditemuuid,
            "sequenceStart" => sequenceStart
         }
        NxBalls::commit(item)
        item
    end

    # --------------------------------------------------
    # Data NxBalls

    # NxBalls::toRunningStatement(nxball)
    def self.toRunningStatement(nxball)
        if nxball["isActive"] then
            timespan = (Time.new.to_i - nxball["unixtime"]).to_f/3600
            sequenceStartStr = nxball["sequenceStart"] ? ", sequence: #{((Time.new.to_i - nxball["sequenceStart"]).to_f/3600).round(2)} hours" : ""
            "(running for #{timespan.round(2)} hours#{sequenceStartStr})"
        else
            "(paused)"
        end
    end

    # NxBalls::toString(nxball)
    def self.toString(nxball)
        "(nxball) #{nxball["accounts"].map{|account| account["description"]}.join("; ")} #{NxBalls::toRunningStatement(nxball)}"
    end

    # --------------------------------------------------
    # Data Item

    # NxBalls::getNxBallForItemOrNull(item)
    def self.getNxBallForItemOrNull(item)
        NxBalls::items()
            .select{|nxball| nxball["itemuuid"] == item["uuid"] }
            .first
    end

    # NxBalls::itemIsRunning(item)
    def self.itemIsRunning(item)
        !NxBalls::getNxBallForItemOrNull(item).nil?
    end

    # NxBalls::itemUnrealisedRunTimeInSecondsOrNull(item)
    def self.itemUnrealisedRunTimeInSecondsOrNull(item)
        nxball = NxBalls::getNxBallForItemOrNull(item)
        return nil if nxball.nil?
        Time.new.to_f - nxball["unixtime"]
    end

    # NxBalls::itemRealisedAndUnrealsedTimeInSeconds(item)
    def self.itemRealisedAndUnrealsedTimeInSeconds(item)
        realisedTime = Bank::valueAtDate(item["uuid"], CommonUtils::today())
        unrealisedTime = NxBalls::itemUnrealisedRunTimeInSecondsOrNull(item) || 0
        realisedTime + unrealisedTime
    end

    # --------------------------------------------------
    # Operations

    # NxBalls::close(nxball)
    def self.close(nxball)
        # We only perform bank update if the ball was active.
        if nxball["isActive"] then
            timespan = Time.new.to_i - nxball["unixtime"]
            nxball["accounts"].each{|account|
                puts "Bank: putting #{timespan} seconds into '#{account["description"]}', account: #{account["number"]}"
                Bank::put(account["number"], timespan)
            }
        end
        NxBalls::destroy(nxball["uuid"])
    end

    # NxBalls::pause(nxball)
    def self.pause(nxball)
        if nxball["isActive"] then
            # Closing the existing one, and issuing
            # a non active one
            NxBalls::close(nxball)
            NxBalls::issue(nxball["accounts"], nxball["itemuuid"], nil, false)
        else
            puts JSON.pretty_generate(nxball)
            puts "This NxBall is not active, it cannot be paused"
            LucilleCore::pressEnterToContinue()
        end
    end

    # NxBalls::pursue(nxball)
    def self.pursue(nxball)
        # We can pursue both active and inactive balls. The only difference is that pursuing an active ball sets the sequence start
        # We close the existing ball and issue a new one with the same payload (and it doesn't need to have the same uuid)
        NxBalls::close(nxball)
        NxBalls::issue(nxball["accounts"], nxball["itemuuid"], nxball["isActive"] ? nxball["unixtime"] : nil, true)
    end

    # NxBalls::closeNxBallForItemOrNothing(item)
    def self.closeNxBallForItemOrNothing(item)
        nxball = NxBalls::getNxBallForItemOrNull(item)
        return if nxball.nil?
        NxBalls::close(nxball)
    end
end
