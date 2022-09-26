
# encoding: UTF-8

class NxBallsIO 

    # --------------------------------------------------------------------
    # IO

=begin
    XCacheSets::values(setuuid: String): Array[Value]
    XCacheSets::set(setuuid: String, valueuuid: String, value)
    XCacheSets::getOrNull(setuuid: String, valueuuid: String): nil | Value
    XCacheSets::destroy(setuuid: String, valueuuid: String)
=end

    # NxBallsIO::nxballs()
    def self.nxballs()
        XCacheSets::values("38288c92-0dfa-4e85-83cc-1a2cc2300d47")
    end

    # NxBallsIO::getItemByIdOrNull(uuid)
    def self.getItemByIdOrNull(uuid)
        XCacheSets::getOrNull("38288c92-0dfa-4e85-83cc-1a2cc2300d47", uuid)
    end

    # NxBallsIO::commitItem(item)
    def self.commitItem(item)
        XCacheSets::set("38288c92-0dfa-4e85-83cc-1a2cc2300d47", item["uuid"], item)
    end

    # NxBallsIO::destroyItem(uuid)
    def self.destroyItem(uuid)
        XCacheSets::destroy("38288c92-0dfa-4e85-83cc-1a2cc2300d47", uuid)
    end

end

class NxBallsService

=begin

    status {
        "type"                    => "running",
        "thisSprintStartUnixtime" => Float,
        "lastMarginCallUnixtime"  => nil or Float,
        "bankedTimeInSeconds"     => Float
    }

    {
        "type"                    => "paused",
        "bankedTimeInSeconds"     => Float
    }

=end

    # NxBallsService::makeRunningStatus(lastMarginCallUnixtime, bankedTimeInSeconds)
    def self.makeRunningStatus(lastMarginCallUnixtime, bankedTimeInSeconds)
        {
            "type"                    => "running",
            "thisSprintStartUnixtime" => Time.new.to_f, # NxBall start (or restart from pause) time
            "lastMarginCallUnixtime"  => lastMarginCallUnixtime,
            "bankedTimeInSeconds"     => bankedTimeInSeconds
        }
    end

    # NxBallsService::makePausedStatus(bankedTimeInSeconds)
    def self.makePausedStatus(bankedTimeInSeconds)
        {
            "type"                    => "paused",
            "bankedTimeInSeconds"     => bankedTimeInSeconds
        }
    end

    # --------------------------------------------------------------------
    # Operations

    # NxBallsService::issue(uuid, description, accounts, desiredBankedTimeInSeconds)
    def self.issue(uuid, description, accounts, desiredBankedTimeInSeconds)
        return if NxBallsIO::getItemByIdOrNull(uuid)
        nxball = {
            "uuid"        => uuid,
            "mikuType"    => "NxBall.v2",
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "desiredBankedTimeInSeconds" => desiredBankedTimeInSeconds,
            "status"      => NxBallsService::makeRunningStatus(nil, 0),
            "accounts"    => accounts
        }
        NxBallsIO::commitItem(nxball)
    end

    # NxBallsService::isRunning(uuid)
    def self.isRunning(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        return false if nxball.nil?
        nxball["status"]["type"] == "running"
    end

    # NxBallsService::isPaused(uuid)
    def self.isPaused(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        return false if nxball.nil?
        nxball["status"]["type"] == "paused"
    end

    # NxBallsService::isPresent(uuid)
    def self.isPresent(uuid)
        NxBallsService::isRunning(uuid) or NxBallsService::isPaused(uuid)
    end

    # NxBallsService::marginCall(uuid)
    def self.marginCall(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        return if nxball.nil?
        return if nxball["status"]["type"] != "running"
        referenceTimeForUnrealisedAccounting = nxball["status"]["lastMarginCallUnixtime"] ? nxball["status"]["lastMarginCallUnixtime"] : nxball["status"]["thisSprintStartUnixtime"]
        timespan = Time.new.to_f - referenceTimeForUnrealisedAccounting
        timespan = [timespan, 3600*2].min
        nxball["accounts"].each{|account|
            Bank::put(account, timespan)
        }
        nxball["status"]["lastMarginCallUnixtime"] = Time.new.to_i
        nxball["status"]["bankedTimeInSeconds"] = nxball["status"]["bankedTimeInSeconds"] + timespan
        NxBallsIO::commitItem(nxball)
    end

    # NxBallsService::marginCallIfIsTime(uuid)
    def self.marginCallIfIsTime(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        return if nxball.nil?
        return if nxball["status"]["type"] != "running"
        referenceTimeForUnrealisedAccounting = nxball["status"]["lastMarginCallUnixtime"] ? nxball["status"]["lastMarginCallUnixtime"] : nxball["status"]["thisSprintStartUnixtime"]
        return if (Time.new.to_f - referenceTimeForUnrealisedAccounting) < 600
        NxBallsService::marginCall(uuid)
    end

    # NxBallsService::pause(uuid) # timespan in seconds or null
    def self.pause(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        return if nxball.nil?
        return if nxball["status"]["type"] != "running"
        NxBallsService::marginCall(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        nxball["status"] = NxBallsService::makePausedStatus(nxball["status"]["bankedTimeInSeconds"])
        NxBallsIO::commitItem(nxball)
    end

    # NxBallsService::pursue(uuid)
    def self.pursue(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        return nil if nxball.nil?
        if nxball["status"]["type"] == "running" then
            NxBallsService::marginCall(uuid)
            nxball = NxBallsIO::getItemByIdOrNull(uuid)
            # If pursue was called while the item was running, it was because of an 1 hour notification which was shown, we need to reset it.
            nxball["status"]["thisSprintStartUnixtime"] = Time.new.to_f
            NxBallsIO::commitItem(nxball)
        end
        if nxball["status"]["type"] == "paused" then
            nxball["status"] = NxBallsService::makeRunningStatus(nil, nxball["status"]["bankedTimeInSeconds"])
            NxBallsIO::commitItem(nxball)
        end
    end

    # NxBallsService::close(uuid, verbose) # timespan in seconds or null
    def self.close(uuid, verbose)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        return nil if nxball.nil?
        timespan = nil
        if nxball["status"]["type"] == "running" then
            if verbose then
                puts "(#{Time.new.to_s}) nxball total time: #{((nxball["status"]["bankedTimeInSeconds"] + Time.new.to_i - nxball["status"]["thisSprintStartUnixtime"]).to_f/3600).round(2)} hours"
            end
            referenceTimeForUnrealisedAccounting = nxball["status"]["lastMarginCallUnixtime"] ? nxball["status"]["lastMarginCallUnixtime"] : nxball["status"]["thisSprintStartUnixtime"]
            timespan = Time.new.to_f - referenceTimeForUnrealisedAccounting
            timespan = [timespan, 3600*2].min
            nxball["accounts"].each{|account|
                puts "(#{Time.new.to_s}) putting #{timespan} seconds into account: #{account}" if verbose
                Bank::put(account, timespan)
            }
        end
        if nxball["status"]["type"] == "paused" then
            if verbose then
                puts "(#{Time.new.to_s}) Closing paused NxBall"
            end
        end
        NxBallsIO::destroyItem(uuid)
        timespan
    end

    # --------------------------------------------------------------------
    # Information

    # NxBallsService::thisSprintStartUnixtimeOrNull(uuid)
    def self.thisSprintStartUnixtimeOrNull(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        if nxball.nil? then
            return nil
        end
        if nxball["status"]["type"] == "paused" then
            return nil
        end
        nxball["status"]["thisSprintStartUnixtime"]
    end

    # NxBallsService::activityStringOrEmptyString(leftSide, uuid, rightSide)
    def self.activityStringOrEmptyString(leftSide, uuid, rightSide)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        if nxball.nil? then
            return ""
        end
        if nxball["status"]["type"] == "paused" then
            return "#{leftSide}#{"paused".green}#{rightSide}"
        end
        currentSprintTimeInSecond = Time.new.to_i - nxball["status"]["thisSprintStartUnixtime"]
        realisedTimeInSeconds     = nxball["status"]["bankedTimeInSeconds"]
        referenceTimeForUnrealisedAccounting = nxball["status"]["lastMarginCallUnixtime"] ? nxball["status"]["lastMarginCallUnixtime"] : nxball["status"]["thisSprintStartUnixtime"]
        unrealiseTimeInSeconds    = Time.new.to_i - referenceTimeForUnrealisedAccounting
        currentTotalTimeInSeconds = realisedTimeInSeconds + unrealiseTimeInSeconds
        "#{leftSide}current sprint: #{(currentSprintTimeInSecond.to_f/3600).round(2)} h, nxball total #{(currentTotalTimeInSeconds.to_f/3600).round(2)} hours#{rightSide}"
    end
end
