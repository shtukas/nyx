
# encoding: UTF-8

class NxBallsService

    # Operations

    # NxBallsService::issue(uuid, description, accounts)
    def self.issue(uuid, description, accounts)
        return if XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
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
        XCacheSets::set("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid, nxball)
    end

    # NxBallsService::isRunning(uuid)
    def self.isRunning(uuid)
        nxball = XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return false if nxball.nil?
        nxball["status"]["type"] == "running"
    end

    # NxBallsService::isPaused(uuid)
    def self.isPaused(uuid)
        nxball = XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return false if nxball.nil?
        nxball["status"]["type"] == "paused"
    end

    # NxBallsService::isActive(uuid)
    def self.isActive(uuid)
        NxBallsService::isRunning(uuid) or NxBallsService::isPaused(uuid)
    end

    # NxBallsService::marginCall(uuid)
    def self.marginCall(uuid)
        nxball = XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        return if nxball["status"]["type"] != "running"
        timespan = Time.new.to_f - nxball["status"]["cursorUnixtime"]
        timespan = [timespan, 3600*2].min
        nxball["accounts"].each{|account|
            Bank::put(account, timespan)
        }
        nxball["status"]["cursorUnixtime"] = Time.new.to_i
        XCacheSets::set("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid, nxball)
    end

    # NxBallsService::pursue(uuid)
    def self.pursue(uuid)
        nxball = XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        NxBallsService::close(uuid, true)
        NxBallsService::issue(uuid, nxball["description"], nxball["accounts"])
    end

    # NxBallsService::pause(uuid) # timespan in seconds or null
    def self.pause(uuid)
        nxball = XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return nil if nxball.nil?
        timespan = NxBallsService::close(uuid, true)
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
        XCacheSets::set("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid, nxball)
        timespan
    end

    # NxBallsService::close(uuid, verbose) # timespan in seconds or null
    def self.close(uuid, verbose)
        nxball = XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return nil if nxball.nil?
        timespan = nil
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
        XCacheSets::destroy("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        timespan
    end

    # NxBallsService::closeWithAsking(uuid)
    def self.closeWithAsking(uuid)
        nxball = XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        if !LucilleCore::askQuestionAnswerAsBoolean("(#{Time.new.to_s}) Running '#{nxball["description"]}'. Continue ? ", false) then
            NxBallsService::close(uuid, true)
        end
    end

    # Information

    # NxBallsService::cursorUnixtimeOrNow(uuid)
    def self.cursorUnixtimeOrNow(uuid)
        nxball = XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
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
        nxball = XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        if nxball.nil? then
            return Time.new.to_i 
        end
        if nxball["status"]["type"] == "paused" then
            return Time.new.to_i 
        end
        nxball["status"]["startUnixtime"]
    end

    # NxBallsService::activityStringOrEmptyString(leftSide, uuid, rightSide)
    def self.activityStringOrEmptyString(leftSide, uuid, rightSide)
        nxball = XCacheSets::getOrNull("a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        if nxball.nil? then
            return ""
        end
        if nxball["status"]["type"] == "paused" then
            return "#{leftSide}#{"paused".green}#{rightSide}"
        end
        "#{leftSide}running for #{((Time.new.to_i-nxball["status"]["startUnixtime"]).to_f/3600).round(2)} hours#{rightSide}"
    end

    # NxBallsService::somethingIsRunning()
    def self.somethingIsRunning()
        nxballs = XCacheSets::values("a69583a5-8a13-46d9-a965-86f95feb6f68")
                    .select{|nxball| NxBallsService::isRunning(nxball["uuid"]) }
        !nxballs.empty?
    end
end

Thread.new {
    loop {
        sleep 60

        XCacheSets::values("a69583a5-8a13-46d9-a965-86f95feb6f68").each{|nxball|
            uuid = nxball["uuid"]
            next if (Time.new.to_i - NxBallsService::cursorUnixtimeOrNow(uuid)) < 600
            NxBallsService::marginCall(uuid)
        }

        XCacheSets::values("a69583a5-8a13-46d9-a965-86f95feb6f68").each{|nxball|
            uuid = nxball["uuid"]
            next if (Time.new.to_i - NxBallsService::startUnixtimeOrNow(uuid)) < 3600
            CommonUtils::onScreenNotification("Catalyst", "NxBall running for more than an hour")
        }
        
    }
}
