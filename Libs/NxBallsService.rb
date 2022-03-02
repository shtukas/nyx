
# encoding: UTF-8

class NxBallsService

    # Operations

    # NxBallsService::issue(uuid, description, accounts)
    def self.issue(uuid, description, accounts)
        return if BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        start = Time.new.to_f
        nxball = {
            "uuid" => uuid,
            "mikuType" => "NxBall.v2",
            "unixtime" => Time.new.to_f,
            "description" => description,
            "status" => {
                "type" => "running",
                "startUnixtime" => start,
                "cursorUnixtime" => start,
            },
            "accounts" => accounts
        }
        BTreeSets::set(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid, nxball)
    end

    # NxBallsService::isRunning(uuid)
    def self.isRunning(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return false if nxball.nil?
        nxball["status"]["type"] == "running"
    end

    # NxBallsService::marginCall(uuid)
    def self.marginCall(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        return if nxball["status"]["type"] != "running"
        timespan = Time.new.to_f - nxball["status"]["cursorUnixtime"]
        timespan = [timespan, 3600*2].min
        nxball["accounts"].each{|account|
            Bank::put(account, timespan)
        }
        nxball["status"]["cursorUnixtime"] = Time.new.to_i
        BTreeSets::set(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid, nxball)
    end

    # NxBallsService::pursue(uuid)
    def self.pursue(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        NxBallsService::close(uuid, true)
        NxBallsService::issue(uuid, nxball["description"], nxball["accounts"])
    end

    # NxBallsService::pause(uuid)
    def self.pause(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        NxBallsService::close(uuid, true)
        nxball = {
            "uuid" => nxball["uuid"],
            "mikuType" => "NxBall.v2",
            "unixtime" => nxball["unixtime"],
            "description" => nxball["description"],
            "status" => {
                "type" => "paused",
            },
            "accounts" => nxball["accounts"]
        }
        BTreeSets::set(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid, nxball)
    end

    # NxBallsService::close(uuid, verbose)
    def self.close(uuid, verbose)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        if nxball["status"]["type"] == "running" then
            if verbose then
                puts "(#{Time.new.to_s}) Running for #{((Time.new.to_i-nxball["status"]["startUnixtime"]).to_f/3600).round(2)} hours"
            end
            timespan = Time.new.to_f - nxball["status"]["cursorUnixtime"]
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
        BTreeSets::destroy(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
    end

    # NxBallsService::closeWithAsking(uuid)
    def self.closeWithAsking(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        if !LucilleCore::askQuestionAnswerAsBoolean("(#{Time.new.to_s}) Running '#{nxball["description"]}'. Continue ? ", false) then
            NxBallsService::close(uuid, true)
        end
    end

    # Information

    # NxBallsService::cursorUnixtimeOrNow(uuid)
    def self.cursorUnixtimeOrNow(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        if nxball.nil? then
            return Time.new.to_i 
        end
        if nxball["status"]["type"] == "paused" then
            return Time.new.to_i 
        end
        nxball["status"]["cursorUnixtime"]
    end

    # NxBallsService::startUnixtimeOrNow(uuid)
    def self.startUnixtimeOrNow(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        if nxball.nil? then
            return Time.new.to_i 
        end
        if nxball["status"]["type"] == "paused" then
            return Time.new.to_i 
        end
        nxball["status"]["startUnixtime"]
    end

    # NxBallsService::runningStringOrEmptyString(leftSide, uuid, rightSide)
    def self.runningStringOrEmptyString(leftSide, uuid, rightSide)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        if nxball.nil? then
            return ""
        end
        if nxball["status"]["type"] == "paused" then
            return "#{leftSide}paused#{rightSide}"
        end
        "#{leftSide}running for #{((Time.new.to_i-nxball["status"]["startUnixtime"]).to_f/3600).round(2)} hours#{rightSide}"
    end
end

Thread.new {
    loop {
        sleep 60

        BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68").each{|nxball|
            uuid = nxball["uuid"]
            next if (Time.new.to_i - NxBallsService::cursorUnixtimeOrNow(uuid)) < 600
            NxBallsService::marginCall(uuid)
        }

        BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68").each{|nxball|
            uuid = nxball["uuid"]
            next if (Time.new.to_i - NxBallsService::startUnixtimeOrNow(uuid)) < 3600
            Utils::onScreenNotification("Catalyst", "NxBall running for more than an hour")
        }
        
    }
}
