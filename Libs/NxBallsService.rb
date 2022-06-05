
# encoding: UTF-8

class NxBallsIO 

    # --------------------------------------------------------------------
    # IO

    # NxBallsIO::getDataSet()
    def self.getDataSet()
        dataset = XCache::getOrNull("2dd5cedc-4ceb-4f71-b2dc-3ed039eb3ee9")
        dataset ? JSON.parse(dataset) : {}
    end

    # NxBallsIO::setDataSet(dataset)
    def self.setDataSet(dataset)
        XCache::set("2dd5cedc-4ceb-4f71-b2dc-3ed039eb3ee9", JSON.generate(dataset))
    end

    # NxBallsIO::getItemByIdOrNull(uuid)
    def self.getItemByIdOrNull(uuid)
        NxBallsIO::getDataSet()[uuid]
    end

    # NxBallsIO::commitItem(item)
    def self.commitItem(item)
        dataset = NxBallsIO::getDataSet()
        dataset[item["uuid"]] = item
        NxBallsIO::setDataSet(dataset)
    end

    # NxBallsIO::getItems()
    def self.getItems()
        NxBallsIO::getDataSet().values
    end

    # NxBallsIO::destroyItem(uuid)
    def self.destroyItem(uuid)
        dataset = NxBallsIO::getDataSet()
        dataset.delete(uuid)
        NxBallsIO::setDataSet(dataset)
    end

end

class NxBallsService

    # --------------------------------------------------------------------
    # Operations

    # NxBallsService::issue(uuid, description, accounts)
    def self.issue(uuid, description, accounts)
        return if NxBallsIO::getItemByIdOrNull(uuid)
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

    # NxBallsService::isActive(uuid)
    def self.isActive(uuid)
        NxBallsService::isRunning(uuid) or NxBallsService::isPaused(uuid)
    end

    # NxBallsService::marginCall(uuid)
    def self.marginCall(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        return if nxball.nil?
        return if nxball["status"]["type"] != "running"
        timespan = Time.new.to_f - nxball["status"]["cursorUnixtime"]
        timespan = [timespan, 3600*2].min
        nxball["accounts"].each{|account|
            Bank::put(account, timespan)
        }
        nxball["status"]["cursorUnixtime"] = Time.new.to_i
        NxBallsIO::commitItem(nxball)
    end

    # NxBallsService::pursue(uuid)
    def self.pursue(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        return if nxball.nil?
        NxBallsService::close(uuid, true)
        NxBallsService::issue(uuid, nxball["description"], nxball["accounts"])
    end

    # NxBallsService::pause(uuid) # timespan in seconds or null
    def self.pause(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
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
        NxBallsIO::commitItem(nxball)
        timespan
    end

    # NxBallsService::close(uuid, verbose) # timespan in seconds or null
    def self.close(uuid, verbose)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
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
        NxBallsIO::destroyItem(uuid)
        timespan
    end

    # NxBallsService::closeWithAsking(uuid)
    def self.closeWithAsking(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
        return if nxball.nil?
        if !LucilleCore::askQuestionAnswerAsBoolean("(#{Time.new.to_s}) Running '#{nxball["description"]}'. Continue ? ", false) then
            NxBallsService::close(uuid, true)
        end
    end

    # --------------------------------------------------------------------
    # Information

    # NxBallsService::cursorUnixtimeOrNow(uuid)
    def self.cursorUnixtimeOrNow(uuid)
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
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
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
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
        nxball = NxBallsIO::getItemByIdOrNull(uuid)
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
        nxballs = NxBallsIO::getItems()
                    .select{|nxball| NxBallsService::isRunning(nxball["uuid"]) }
        !nxballs.empty?
    end
end

Thread.new {
    loop {
        sleep 60

        NxBallsIO::getItems().each{|nxball|
            uuid = nxball["uuid"]
            next if (Time.new.to_i - NxBallsService::cursorUnixtimeOrNow(uuid)) < 600
            NxBallsService::marginCall(uuid)
        }

        NxBallsIO::getItems().each{|nxball|
            uuid = nxball["uuid"]
            next if (Time.new.to_i - NxBallsService::startUnixtimeOrNow(uuid)) < 3600
            CommonUtils::onScreenNotification("Catalyst", "NxBall running for more than an hour")
        }
        
    }
}
