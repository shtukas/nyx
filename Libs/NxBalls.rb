
class NxBalls

    # NxBalls doesn't read or write the database to avoid race conditions

    # ---------------------------------
    # Utils

    # NxBalls::makeNxBallOrNull(item)
    def self.makeNxBallOrNull(item)
        tc = nil
        if item["field10"] then
            tc = ObjectStore1::getItemByUUIDOrNull(item["field10"])
        end
        if tc.nil? then
            tc = NxTimeCommitments::interactivelySelectOneOrNull()
        end
        return nil if tc.nil?
        {
            "type"          => "running",
            "startunixtime" => Time.new.to_i,
            "field10"       => tc["uuid"],
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
        nxball = NxBalls::makeNxBallOrNull(item)
        item["field9"] = nxball
        item
    end

    # NxBalls::stop(item) # [item, timespanInSeconds, field10]
    def self.stop(item)
        return [item, 0] if !NxBalls::itemIsRunning(item)
        nxball = item["field9"]
        timespanInSeconds = Time.new.to_i - nxball["startunixtime"]
        item["field9"] = nil
        [item, timespanInSeconds, nxball["field10"]]
    end

    # NxBalls::pause(item) # [item, timespanInSeconds, field10]
    def self.pause(item)
        return if !NxBalls::itemIsRunning(item)
        nxball = item["field9"]
        timespanInSeconds = Time.new.to_i - nxball["startunixtime"]
        nxball["type"] = "paused"
        item["field9"] = nxball
        [item, timespanInSeconds, nxball["field10"]]
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
            return "(nxball: running for #{ ((Time.new.to_i - nxball["startunixtime"]).to_f/3600).round(2) } hours, sequence started #{ ((Time.new.to_i - nxball["sequencestart"]).to_f/3600).round(2) } hours ago) (tc: #{NxTimeCommitments::uuidToDescription(nxball["field10"])})"
        end
        if nxball["type"] == "running" then
            return "(nxball: running for #{ ((Time.new.to_i - nxball["startunixtime"]).to_f/3600).round(2) } hours) (tc: #{NxTimeCommitments::uuidToDescription(nxball["field10"])})"
        end
        if nxball["type"] == "paused" then
            return "(nxball: paused) (tc: #{NxTimeCommitments::uuidToDescription(nxball["field10"])})"
        end
        raise "(error: 93abde39-fd9d-4aa5-8e56-d09cf47a0f46) nxball: #{nxball}"
    end

    # NxBalls::nxballSuffixStatus(nxball)
    def self.nxballSuffixStatus(nxball)
        return "" if nxball.nil?
        " #{NxBalls::nxBallToString(nxball)}"
    end

end