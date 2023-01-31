
class NxBalls

    # NxBalls doesn't read or write the database to avoid race conditions

    # ---------------------------------
    # Utils

    # NxBalls::makeNxBall()
    def self.makeNxBall()
        tc = NxTimeCommitments::interactivelySelectOneOrNull()
        {
            "type"          => "running",
            "startunixtime" => Time.new.to_i,
            "tcId"          => tc ? tc["uuid"] : nil,
            "tcName"        => tc ? tc["description"] : nil, 
            "sequencestart" => nil
        }
    end

    # ---------------------------------
    # Item -> item # transforms

    # NxBalls::getNxballOrNull(item)
    def self.getNxballOrNull(item)
        item["field9"]
    end

    # NxBalls::itemIsRunning(item)
    # returns false if the item doesn't have a nxball of is paused
    def self.itemIsRunning(item)
        nxball = NxBalls::getNxballOrNull(item)
        return false if nxball.nil?
        nxball["type"] == "running"
    end

    # NxBalls::itemIsPaused(item)
    def self.itemIsPaused(item)
        nxball = NxBalls::getNxballOrNull(item)
        return false if nxball.nil?
        nxball["type"] == "paused"
    end

    # NxBalls::itemIsBallFree(item)
    def self.itemIsBallFree(item)
        NxBalls::getNxballOrNull(item).nil?
    end

    # NxBalls::start(item) # item
    def self.start(item)
        return item if !NxBalls::itemIsBallFree(item)
        nxball = NxBalls::makeNxBall()
        item["field9"] = nxball
        item
    end

    # NxBalls::stop(item) # [item, timespanInSeconds, tcId]
    def self.stop(item)
        return [item, 0] if !NxBalls::itemIsRunning(item)
        nxball = item["field9"]
        timespanInSeconds = Time.new.to_i - nxball["startunixtime"]
        item["field9"] = nil
        [item, timespanInSeconds, nxball["tcId"]]
    end

    # NxBalls::pause(item) # [item, timespanInSeconds, tcId]
    def self.pause(item)
        return if !NxBalls::itemIsRunning(item)
        nxball = item["field9"]
        timespanInSeconds = Time.new.to_i - nxball["startunixtime"]
        nxball["type"] = "paused"
        item["field9"] = nxball
        [item, timespanInSeconds, nxball["tcId"]]
    end

    # NxBalls::pursue(item) # item
    def self.pursue(item)
        return item if !NxBalls::itemIsPaused(item)
        nxball = item["field9"]
        nxball["sequencestart"] = nxball["sequencestart"] || nxball["startunixtime"]
        nxball["type"] = "running"
        nxball["startunixtime"] = Time.new.to_i
        item["field9"] = nxball
        item
    end

    # ---------------------------------
    # Data

    # NxBalls::nxBallToString(nxball)
    def self.nxBallToString(nxball)
        if nxball["type"] == "running" and nxball["sequencestart"] then
            return "(nxball: running for #{ ((Time.new.to_i - nxball["startunixtime"]).to_f/3600).round(2) } hours, sequence started #{ ((Time.new.to_i - nxball["sequencestart"]).to_f/3600).round(2) } hours ago)"
        end
        if nxball["type"] == "running" then
            return "(nxball: running for #{ ((Time.new.to_i - nxball["startunixtime"]).to_f/3600).round(2) } hours)"
        end
        if nxball["type"] == "paused" then
            return "(nxball: paused)"
        end
        raise "(error: 93abde39-fd9d-4aa5-8e56-d09cf47a0f46) nxball: #{nxball}"
    end

    # NxBalls::nxballSuffixStatus(nxball)
    def self.nxballSuffixStatus(nxball)
        return "" if nxball.nil?
        " #{NxBalls::nxBallToString(nxball)}"
    end

end