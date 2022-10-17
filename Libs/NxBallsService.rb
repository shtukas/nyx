
# encoding: UTF-8

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

    # NxBallsService::issue(owneruuid, description, accounts, desiredBankedTimeInSeconds)
    def self.issue(owneruuid, description, accounts, desiredBankedTimeInSeconds)
        nxball = {
            "uuid"         => SecureRandom.uuid,
            "phage_uuid"   => SecureRandom.uuid,
            "phage_time"   => Time.new.to_f,
            "phage_alive"  => true,
            "owneruuid"    => owneruuid,
            "mikuType"     => "NxBall.v2",
            "unixtime"     => Time.new.to_f,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "desiredBankedTimeInSeconds" => desiredBankedTimeInSeconds,
            "status"       => NxBallsService::makeRunningStatus(nil, 0),
            "accounts"     => accounts
        }
        PhagePublic::commit(nxball)
    end

    # NxBallsService::getBallByOwnerOrNull(owneruuid)
    def self.getBallByOwnerOrNull(owneruuid)
        PhagePublic::mikuTypeToObjects("NxBall.v2")
            .select{|nxball| nxball["owneruuid"] == owneruuid }
            .first
    end

    # NxBallsService::itemToNxBallOpt(item)
    def self.itemToNxBallOpt(item)
        NxBallsService::getBallByOwnerOrNull(item["uuid"])
    end

    # NxBallsService::isRunning(nxBallOpt)
    def self.isRunning(nxBallOpt)
        return false if nxBallOpt.nil?
        nxBallOpt["status"]["type"] == "running"
    end

    # NxBallsService::isPaused(nxball)
    def self.isPaused(nxball)
        nxball["status"]["type"] == "paused"
    end

    # NxBallsService::isActive(nxBallOpt)
    def self.isActive(nxBallOpt)
        return false if nxBallOpt.nil?
        nxball = nxBallOpt
        NxBallsService::isRunning(nxball) or NxBallsService::isPaused(nxball)
    end

    # NxBallsService::marginCall(uuid)
    def self.marginCall(uuid)
        nxball = PhagePublic::getObjectOrNull(uuid)
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
        PhagePublic::commit(nxball)
    end

    # NxBallsService::marginCallIfIsTime(nxball)
    def self.marginCallIfIsTime(nxball)
        return if nxball["status"]["type"] != "running"
        referenceTimeForUnrealisedAccounting = nxball["status"]["lastMarginCallUnixtime"] ? nxball["status"]["lastMarginCallUnixtime"] : nxball["status"]["thisSprintStartUnixtime"]
        return if (Time.new.to_f - referenceTimeForUnrealisedAccounting) < 600
        NxBallsService::marginCall(nxball["uuid"])
    end

    # NxBallsService::pause(nxBallOpt)
    def self.pause(nxBallOpt)
        return if nxBallOpt.nil?
        nxball = nxBallOpt
        return if nxball["status"]["type"] != "running"
        NxBallsService::marginCall(uuid)
        nxball = PhagePublic::getObjectOrNull(uuid)
        nxball["status"] = NxBallsService::makePausedStatus(nxball["status"]["bankedTimeInSeconds"])
        PhagePublic::commit(nxball)
    end

    # NxBallsService::pursue(nxBallOpt)
    def self.pursue(nxBallOpt)
        return if nxBallOpt.nil?
        nxball = nxBallOpt
        if nxball["status"]["type"] == "running" then
            NxBallsService::marginCall(uuid)
            nxball = PhagePublic::getObjectOrNull(uuid)
            # If pursue was called while the item was running, it was because of an 1 hour notification which was shown, we need to reset it.
            nxball["status"]["thisSprintStartUnixtime"] = Time.new.to_f
            PhagePublic::commit(nxball)
        end
        if nxball["status"]["type"] == "paused" then
            nxball["status"] = NxBallsService::makeRunningStatus(nil, nxball["status"]["bankedTimeInSeconds"])
            PhagePublic::commit(nxball)
        end
    end

    # NxBallsService::close(nxBallOpt, verbose) # timespan in seconds or null
    def self.close(nxBallOpt, verbose)
        return if nxBallOpt.nil?
        nxball = nxBallOpt
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
        PhagePublic::destroy(nxball["uuid"])
        timespan
    end

    # --------------------------------------------------------------------
    # Information

    # NxBallsService::activityStringOrEmptyString(leftSide, item, rightSide)
    def self.activityStringOrEmptyString(leftSide, item, rightSide)
        nxball = NxBallsService::getBallByOwnerOrNull(item["uuid"])
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
